// Author: Coltin Lappin-Lux
// Date: 9/30/2022

public without sharing class TripAssistantController {
    @AuraEnabled
    public static List<Trip_Day__c> getTripDays(Id tripId){
        List<Trip_Day__c> tripDays = [SELECT Id, Name, Day__c, Location__c, (SELECT Id, Name, Area__c, Duration_Hours__c, RecordTypeId, RecordType.Name FROM Trip_Activities__r) FROM Trip_Day__c WHERE Trip__c = :tripId];

        return tripDays;
    }

    @AuraEnabled
    public static List<Trip_Activity__c> getActivitiesWithoutTripDays(Id tripId){
        List<Trip_Activity__c> activitiesWithoutDays = [SELECT Id, Name, Area__c, Duration_Hours__c, RecordTypeId, RecordType.Name FROM Trip_Activity__c WHERE Trip__c = :tripId];

        return activitiesWithoutDays;
    }
}
