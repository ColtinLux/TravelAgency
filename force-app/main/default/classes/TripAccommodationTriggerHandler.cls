// Author: Coltin Lappin-Lux
// Date: 9/20/2022

public without sharing class TripAccommodationTriggerHandler {
    // ---------------------------------------------------------
    // Trigger Contexts
    // ---------------------------------------------------------
    public static void beforeInsert(List<Trip_Accommodation__c> newTripAccommodations){
        updateAddress(newTripAccommodations);
    }

    public static void beforeUpdate(Map<Id, Trip_Accommodation__c> newTripAccommodationsMap, Map<Id, Trip_Accommodation__c> oldTripAccommodationsMap){
        updateAddress(newTripAccommodationsMap, oldTripAccommodationsMap);
    }

    public static void afterInsert(Map<Id, Trip_Accommodation__c> newTripAccommodationsMap){
        associateToTripDay(newTripAccommodationsMap, new Map<Id, Trip_Accommodation__c>());
    }

    public static void afterUpdate(Map<Id, Trip_Accommodation__c> newTripAccommodationsMap, Map<Id, Trip_Accommodation__c> oldTripAccommodationsMap){
        associateToTripDay(newTripAccommodationsMap, oldTripAccommodationsMap);
    }

    public static void updateAddress(List<Trip_Accommodation__c> newTripAccommodations){
        Set<Id> accommodationIdSet = new Set<Id>();
        for(Trip_Accommodation__c tripAccRecord : newTripAccommodations){
            if(tripAccRecord.Accommodation__c != null){
                accommodationIdSet.add(tripAccRecord.Accommodation__c);
            }
        }

        List<Accommodation__c> accList = [SELECT Id, Address__c FROM Accommodation__c WHERE Id IN :accommodationIdSet];
        Map<Id, Accommodation__c> addressMap = new Map<Id, Accommodation__c>(accList);

        for(Trip_Accommodation__c tripAccRecord : newTripAccommodations){
            if(tripAccRecord.Accommodation__c != null){
                Id accId = tripAccRecord.Accommodation__c;
                if(addressMap.containsKey(accId)){
                    String addressValue = addressMap.get(accId).Address__c;
                    tripAccRecord.Accommodation_Address__c = addressValue;
                }
            }
        }
    }

    public static void updateAddress(Map<Id, Trip_Accommodation__c> newTripAccommodationsMap, Map<Id, Trip_Accommodation__c> oldTripAccommodationsMap){
        List<Trip_Accommodation__c> newTripAccommodationsList = new List<Trip_Accommodation__c>();
        for(Id tripAccId : newTripAccommodationsMap.keySet()){
            Trip_Accommodation__c tripAccRecord = newTripAccommodationsMap.get(tripAccId);
            if(oldTripAccommodationsMap.containsKey(tripAccId)){
                Trip_Accommodation__c oldTripAccRecord = oldTripAccommodationsMap.get(tripAccId);
                if(oldTripAccRecord.Accommodation__c != tripAccRecord.Accommodation__c){
                    newTripAccommodationsList.add(tripAccRecord);
                } else if(oldTripAccRecord.Status__c != tripAccRecord.Status__c){
                    newTripAccommodationsList.add(tripAccRecord);
                }
            } else {
                newTripAccommodationsList.add(tripAccRecord);
            }
        }
        updateAddress(newTripAccommodationsList);
    }

    // ---------------------------------------------------------
    // Relate to Trip Day Records
    // ---------------------------------------------------------
    public static void associateToTripDay(Map<Id, Trip_Accommodation__c> newTripAccommodationsMap, Map<Id, Trip_Accommodation__c> oldTripAccommodationsMap){
        Map<Id, List<Trip_Accommodation__c>> tripToAccMap = new Map<Id, List<Trip_Accommodation__c>>();
        for(Id tripAccId : newTripAccommodationsMap.keySet()){
            Trip_Accommodation__c newTripAccRecord = newTripAccommodationsMap.get(tripAccId);
            if(newTripAccRecord.Trip__c != null){
                Id tripId = newTripAccRecord.Trip__c;
                if(oldTripAccommodationsMap.containsKey(tripAccId)){
                    Trip_Accommodation__c oldTripAccRecord = oldTripAccommodationsMap.get(tripAccId);
                    if(newTripAccRecord.Status__c != oldTripAccRecord.Status__c && newTripAccRecord.Status__c == 'Booked'){
                        List<Trip_Accommodation__c> tempList = tripToAccMap.containsKey(tripId) ? tripToAccMap.get(tripId) : new List<Trip_Accommodation__c>();
                        tempList.add(newTripAccRecord);
                        tripToAccMap.put(tripId, tempList);
                    }
                } else {
                    List<Trip_Accommodation__c> tempList = tripToAccMap.containsKey(tripId) ? tripToAccMap.get(tripId) : new List<Trip_Accommodation__c>();
                    tempList.add(newTripAccRecord);
                    tripToAccMap.put(tripId, tempList);
                }
            }
        }

        List<Trip_Day__c> tripDaysToUpdate = new List<Trip_Day__c>();
        for(Trip_Day__c tripDayRecord : [SELECT Id, Name, Date__c, Trip__c, Trip_Accommodation__c FROM Trip_Day__c WHERE Trip__c IN :tripToAccMap.keySet()]){
            Id tripId = tripDayRecord.Trip__c;
            List<Trip_Accommodation__c> accommodationsList = tripToAccMap.containsKey(tripId) ? tripToAccMap.get(tripId) : new List<Trip_Accommodation__c>();
            for(Trip_Accommodation__c tripAccRecord : accommodationsList){
                if(Date.valueOf(tripAccRecord.Check_In__c) <= tripDayRecord.Date__c && tripDayRecord.Date__c < Date.valueOf(tripAccRecord.Check_Out__c)){
                    tripDayRecord.Trip_Accommodation__c = tripAccRecord.Id;
                    tripDaysToUpdate.add(tripDayRecord);
                }
            }
        }

        update tripDaysToUpdate;
    }
}