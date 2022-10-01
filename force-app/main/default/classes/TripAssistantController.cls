// Author: Coltin Lappin-Lux
// Date: 9/30/2022

public without sharing class TripAssistantController {
    @AuraEnabled
    public static String getTripDays(Id tripId){
        List<Trip_Day__c> tripDays = [SELECT Id, Name, Day__c, Location__c, (SELECT Id, Name, Area__c, Duration_Hours__c, RecordTypeId, RecordType.Name FROM Trip_Activities__r) FROM Trip_Day__c WHERE Trip__c = :tripId];

        return JSON.serialize(tripDays);
    }

    @AuraEnabled
    public static String getActivitiesWithoutTripDays(Id tripId){
        List<Trip_Activity__c> activitiesWithoutDays = [SELECT Id, Name, Area__c, Duration_Hours__c, RecordTypeId, RecordType.Name FROM Trip_Activity__c WHERE Trip__c = :tripId AND Trip_Day__c = null];

        return JSON.serialize(activitiesWithoutDays);
    }

    @AuraEnabled
    public static Boolean saveSchedule(Id tripId, String data){
        Boolean result = true;

        List<Trip_Activity__c> existingActivities = [SELECT Id, Name, Area__c, Duration_Hours__c, RecordTypeId, RecordType.Name, Trip_Day__c FROM Trip_Activity__c WHERE Trip__c = :tripId];
        Map<Id, Trip_Activity__c> existingActivityMap = new Map<Id, Trip_Activity__c>(existingActivities);

        List<Trip_Activity__c> formattedData = (List<Trip_Activity__c>) JSON.deserialize(data, List<Trip_Activity__c>.class);

        System.debug(formattedData);

        List<Trip_Activity__c> updatedActivities = new List<Trip_Activity__c>();
        for(Trip_Activity__c dataRec : formattedData){
            Id recId = dataRec.Id;
            Id tripDayId = dataRec.Trip_Day__c;
            if(existingActivityMap.containsKey(recId)){
                Trip_Activity__c existingActivity = existingActivityMap.get(recId);
                if(existingActivity.Trip_Day__c != tripDayId){
                    existingActivity.Trip_Day__c = tripDayId;
                    updatedActivities.add(existingActivity);
                }
            } else {
                Trip_Activity__c updatedRec = new Trip_Activity__c(Id = recId);
                updatedRec.Trip_Day__c = tripDayId;
                updatedActivities.add(updatedRec);
            }
        }

        try{
            update updatedActivities;
        } catch(Exception e){
            return false;
        }

        return result;
    }
}