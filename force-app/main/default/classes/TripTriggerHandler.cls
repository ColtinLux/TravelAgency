// Author: Coltin Lappin-Lux
// Date: 9/17/2022

public without sharing class TripTriggerHandler {
    // ---------------------------------------------------------
    // Trigger Contexts
    // ---------------------------------------------------------
    public static void beforeInsert(List<Trip__c> newTrips){
        //TODO:
    }

    public static void beforeUpdate(Map<Id, Trip__c> newTripsMap, Map<Id, Trip__c> oldTripsMap){
        //TODO:
    }

    public static void afterInsert(Map<Id, Trip__c> newTripsMap){
        tripDays(newTripsMap, new Map<Id, Trip__c>());
    }

    public static void afterUpdate(Map<Id, Trip__c> newTripsMap, Map<Id, Trip__c> oldTripsMap){
        tripDays(newTripsMap, oldTripsMap);
    }

    // ---------------------------------------------------------
    // Trip Day Related Records
    // ---------------------------------------------------------
    public static void tripDays(Map<Id, Trip__c> newTripsMap, Map<Id, Trip__c> oldTripsMap){
        // RESULTS
        List<Trip_Day__c> upsertTripDaysList = new List<Trip_Day__c>();
        List<Trip_Day__c> deleteTripDaysList = new List<Trip_Day__c>();
        
        // CRITERIA
        Set<Id> upsertTripDaysSet = new Set<Id>();
        Set<Id> deleteTripDaysSet = new Set<Id>();
        for(Trip__c newTrip : newTripsMap.values()){
            if(tripDayInsertionCriteria(newTrip, oldTripsMap)){
                upsertTripDaysSet.add(newTrip.Id);
            } else if(tripDayDeletionCriteria(newTrip)){
                deleteTripDaysSet.add(newTrip.Id);
            }
        }

        // DELETE TRIP DAYS
        deleteTripDaysList = [SELECT Id FROM Trip_Day__c WHERE Trip__c IN :deleteTripDaysSet];

        // UPSERT TRIP DAYS
        Map<Id, Map<Date, Trip_Day__c>> existingTripDaysMap = getExistingTripDays(upsertTripDaysSet);
        for(Id tripId : upsertTripDaysSet){
            Trip__c newTrip = newTripsMap.get(tripId);
            Map<Date, Trip_Day__c> existingTripDays = existingTripDaysMap.containsKey(tripId) ? existingTripDaysMap.get(tripId) : new Map<Date, Trip_Day__c>();

            Date currentDate = newTrip.Start_Date__c;
            Date startDate = newTrip.Start_Date__c;
            Date endDate = newTrip.End_Date__c;

            for(Date tripDayDate : existingTripDays.keySet()){
                Trip_Day__c tripDayRecord = existingTripDays.get(tripDayDate);
                if(tripDayDate > endDate || tripDayDate < startDate){
                    deleteTripDaysList.add(tripDayRecord);
                }
            }

            Integer counter = 1;
            while(currentDate <= endDate){
                Trip_Day__c tripDayRecord = existingTripDays.containsKey(currentDate) ? existingTripDays.get(currentDate) : new Trip_Day__c();
                tripDayRecord.Name = 'Day ' + counter;
                tripDayRecord.Date__c = currentDate;
                if(tripDayRecord.Trip__c == null){
                    tripDayRecord.Trip__c = tripId;
                }
                tripDayRecord.First_Day__c = (currentDate == startDate);
                tripDayRecord.Last_Day__c = (currentDate == endDate);
                if(tripDayRecord.First_Day__c){
                    tripDayRecord.Location__c = 'Departing for ' + newTrip.Location__c;
                } else if(tripDayRecord.Last_Day__c){
                    tripDayRecord.Location__c = 'Departing ' + newTrip.Location__c;
                } else {
                    tripDayRecord.Location__c = newTrip.Location__c;
                }
                
                currentDate = currentDate.addDays(1);
                upsertTripDaysList.add(tripDayRecord);

                counter++;
            }
        }

        // DML
        upsert upsertTripDaysList;
        delete deleteTripDaysList;

        tripActivities(newTripsMap, oldTripsMap);
    }

    public static Boolean tripDayInsertionCriteria(Trip__c newTrip, Map<Id, Trip__c> oldTripsMap){
        Id tripId = newTrip.Id;

        Boolean automationEnabled = newTrip.Enable_Trip_Day_Automation__c;
        Boolean hasStartDate = newTrip.Start_Date__c != null;
        Boolean hasEndDate = newTrip.End_Date__c != null;
        Boolean datesValidated = newTrip.Start_Date__c < newTrip.End_Date__c;

        if(hasStartDate && hasEndDate && datesValidated && automationEnabled){
            Boolean isUpdate = oldTripsMap.containsKey(tripId);

            if(isUpdate){
                Trip__c oldTrip = oldTripsMap.get(tripId);
                
                Boolean startDateChange = newTrip.Start_Date__c != oldTrip.Start_Date__c;
                Boolean endDateChange = newTrip.End_Date__c != oldTrip.End_Date__c;
                Boolean automationChange = newTrip.Enable_Trip_Day_Automation__c && !oldTrip.Enable_Trip_Day_Automation__c;
                
                if(startDateChange || endDateChange || automationChange){
                    return true;
                }
            } else {
                return true;
            }
        }

        return false;
    }

    public static Boolean tripDayDeletionCriteria(Trip__c newTrip){
        Boolean automationEnabled = newTrip.Enable_Trip_Day_Automation__c;
        Boolean hasStartDate = newTrip.Start_Date__c != null;
        Boolean hasEndDate = newTrip.End_Date__c != null;
        Boolean datesValidated = newTrip.Start_Date__c < newTrip.End_Date__c;
        if((!hasStartDate || !hasEndDate || !datesValidated) && automationEnabled){
            return true;
        } else {
            return false;
        }
    }

    public static Map<Id, Map<Date, Trip_Day__c>> getExistingTripDays(Set<Id> createTripDaysSet){
        Map<Id, Map<Date, Trip_Day__c>> existingTripDaysMap = new Map<Id, Map<Date, Trip_Day__c>>();

        for(Trip_Day__c day : [SELECT Id, Name, Trip__c, Date__c FROM Trip_Day__c WHERE Trip__c IN :createTripDaysSet]){
            Id tripId = day.Trip__c;
            Map<Date, Trip_Day__c> daysMap = existingTripDaysMap.containsKey(tripId) ? existingTripDaysMap.get(tripId) : new Map<Date, Trip_Day__c>();
            daysMap.put(day.Date__c, day);
            existingTripDaysMap.put(tripId, daysMap);
        }

        return existingTripDaysMap;
    }

    // ---------------------------------------------------------
    // Trip Activity Related Records
    // ---------------------------------------------------------
    public static void tripActivities(Map<Id, Trip__c> newTripsMap, Map<Id, Trip__c> oldTripsMap){
        // RESULT
        List<Trip_Activity__c> newActivities = new List<Trip_Activity__c>();
        List<Trip_Activity__c> deleteActivities = new List<Trip_Activity__c>();

        // RECORD TYPES
        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Trip_Activity__c.getRecordTypeInfosByName();
        Id transportationId = recordTypeMap.get('Transportation').getRecordTypeId();
        Id activityId = recordTypeMap.get('Activity').getRecordTypeId();
        Id mealId = recordTypeMap.get('Meal').getRecordTypeId();

        // GET TRIP DAYS
        Map<Id, List<Trip_Day__c>> existingTripDaysMap = new Map<Id, List<Trip_Day__c>>();
        for(Trip_Day__c tripDayRecord : [SELECT Id, Name, Trip__c, First_Day__c, Last_Day__c, Date__c FROM Trip_Day__c WHERE Trip__c IN :newTripsMap.keySet()]){
            Id tripId = tripDayRecord.Trip__c;
            List<Trip_Day__c> dayList = existingTripDaysMap.containsKey(tripId) ? existingTripDaysMap.get(tripId) : new List<Trip_Day__c>();
            dayList.add(tripDayRecord);
            existingTripDaysMap.put(tripId, dayList);
        }

        // GET TRIP ACTIVITIES
        Map<Id, List<Trip_Activity__c>> existingTripActivityMap = new Map<Id, List<Trip_Activity__c>>();
        for(Trip_Activity__c tripActivityRecord : [SELECT Id, RecordTypeId, Trip__c, Status__c, Trip_Day__c FROM Trip_Activity__c WHERE Trip__c IN :newTripsMap.keySet()]){
            Id tripId = tripActivityRecord.Trip__c;
            List<Trip_Activity__c> activityList = existingTripActivityMap.containsKey(tripId) ? existingTripActivityMap.get(tripId) : new List<Trip_Activity__c>();
            activityList.add(tripActivityRecord);
            existingTripActivityMap.put(tripId, activityList);
        }

        for(Id tripId : newTripsMap.keySet()){
            Trip__c tripRecord = newTripsMap.get(tripId);
            List<Trip_Day__c> tripDays = existingTripDaysMap.containsKey(tripId) ? existingTripDaysMap.get(tripId) : new List<Trip_Day__c>();
            List<Trip_Activity__c> tripActivities = existingTripActivityMap.containsKey(tripId) ? existingTripActivityMap.get(tripId) : new List<Trip_Activity__c>();
            
            Map<Id, Set<Id>> existingActivitiesRecordTypeSetMap = new Map<Id, Set<Id>>();
            for(Trip_Activity__c tripActivityRecord : tripActivities){
                Id tripDayId = tripActivityRecord.Trip_Day__c;
                if(tripDayId != null){
                    Set<Id> activityRecordTypeSet = existingActivitiesRecordTypeSetMap.containsKey(tripDayId) ? existingActivitiesRecordTypeSetMap.get(tripDayId) : new Set<Id>();
                    activityRecordTypeSet.add(tripActivityRecord.RecordTypeId);
                    existingActivitiesRecordTypeSetMap.put(tripDayId, activityRecordTypeSet);
                }

                //REMOVAL CRITERIA
                Boolean criteriaMet = tripActivityDeletionCriteria(tripRecord, tripActivityRecord, recordTypeMap);
                if(criteriaMet){
                    deleteActivities.add(tripActivityRecord);
                }
            }
            
            for(Trip_Day__c tripDayRecord : tripDays){
                Id tripDayId = tripDayRecord.Id;

                // AUTOMATION SETTINGS
                Boolean transportationAutomationEnabled = tripRecord.Enable_Trip_Transportation_Automation__c;
                Boolean activityAutomationEnabled = tripRecord.Enable_Trip_Activity_Automation__c;
                Boolean mealAutomationEnabled = tripRecord.Enable_Trip_Meal_Automation__c;

                //---------------------------------
                // TRANSPORTATION ACTIVITIES
                //---------------------------------
                Boolean hasTransportation = existingActivitiesRecordTypeSetMap.containsKey(tripDayId) ? existingActivitiesRecordTypeSetMap.get(tripDayId).contains(transportationId) : false;
                if(transportationAutomationEnabled && !hasTransportation && (tripDayRecord.First_Day__c || tripDayRecord.Last_Day__c)){
                    Trip_Activity__c newTripActivity = new Trip_Activity__c();
                    newTripActivity.Trip__c = tripId;
                    newTripActivity.Trip_Day__c = tripDayRecord.Id;
                    newTripActivity.RecordTypeId = transportationId;
                    newTripActivity.Date__c = tripDayRecord.Date__c;
    
                    String modeOfTransport = newTripsMap.get(tripId).Mode_Of_Transportation__c;
                    if(modeOfTransport == 'Airplane'){
                        newTripActivity.Name = 'Flight';
                    } else if(modeOfTransport == 'Vehicle'){
                        newTripActivity.Name = 'Drive';
                    } else if(modeOfTransport == 'Boat'){
                        newTripActivity.Name = 'Cruise';
                    } else {
                        newTripActivity.Name = 'Transportation';
                    }
                    newActivities.add(newTripActivity);
                }
                
                //---------------------------------
                // GENERAL ACTIVITIES
                //---------------------------------
                Boolean hasActivity = existingActivitiesRecordTypeSetMap.containsKey(tripDayId) ? existingActivitiesRecordTypeSetMap.get(tripDayId).contains(activityId) : false;
                if(activityAutomationEnabled && !hasActivity){
                    Trip_Activity__c newTripActivity = new Trip_Activity__c();
                    newTripActivity.Trip__c = tripId;
                    newTripActivity.Trip_Day__c = tripDayRecord.Id;
                    newTripActivity.RecordTypeId = activityId;
                    newTripActivity.Date__c = tripDayRecord.Date__c;
                    newTripActivity.Name = tripDayRecord.Name + ' Activity';
                    newActivities.add(newTripActivity);
                }

                //---------------------------------
                // MEAL ACTIVITIES
                //---------------------------------
                Boolean hasMeal = existingActivitiesRecordTypeSetMap.containsKey(tripDayId) ? existingActivitiesRecordTypeSetMap.get(tripDayId).contains(mealId) : false;
                if(mealAutomationEnabled && !hasMeal){
                    Trip_Activity__c newTripActivity = new Trip_Activity__c();
                    newTripActivity.Trip__c = tripId;
                    newTripActivity.Trip_Day__c = tripDayRecord.Id;
                    newTripActivity.RecordTypeId = mealId;
                    newTripActivity.Date__c = tripDayRecord.Date__c;
                    newTripActivity.Name = tripDayRecord.Name + ' Meal';
                    newActivities.add(newTripActivity);
                }
            }
        }

        insert newActivities;
        delete deleteActivities;
    }

    public static Boolean tripActivityDeletionCriteria(Trip__c newTrip, Trip_Activity__c newActivity, Map<String, Schema.RecordTypeInfo> recordTypeMap){
        Boolean hasStartDate = newTrip.Start_Date__c != null;
        Boolean hasEndDate = newTrip.End_Date__c != null;
        Boolean datesValidated = newTrip.Start_Date__c < newTrip.End_Date__c;
        Boolean missingDay = newActivity.Trip_Day__c == null;
        Boolean statusValidation = (newActivity.Status__c == 'New' || newActivity.Status__c == 'Cancelled');
        Boolean baseValidation = ((!hasStartDate || !hasEndDate || !datesValidated || missingDay) && statusValidation);
        
        if(baseValidation){
            // RECORD TYPE
            Id activityRecordType = newActivity.RecordTypeId;
            Id transportationId = recordTypeMap.get('Transportation').getRecordTypeId();
            Id activityId = recordTypeMap.get('Activity').getRecordTypeId();
            Id mealId = recordTypeMap.get('Meal').getRecordTypeId();
            
            // AUTOMATION SETTINGS
            Boolean transportationAutomationEnabled = newTrip.Enable_Trip_Transportation_Automation__c;
            Boolean activityAutomationEnabled = newTrip.Enable_Trip_Activity_Automation__c;
            Boolean mealAutomationEnabled = newTrip.Enable_Trip_Meal_Automation__c;

            if(activityRecordType == transportationId && transportationAutomationEnabled){
                return true;
            } else if(activityRecordType == mealId && mealAutomationEnabled){
                return true;
            } else if(activityRecordType == activityId && activityAutomationEnabled){
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
}
