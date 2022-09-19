// Author: Coltin Lappin-Lux
// Date: 9/17/2022

trigger TripTrigger on Trip__c (after insert, after update) {
    // ----------------------------------
    // Context Variables
    // ----------------------------------
    List<Trip__c> newTrips = Trigger.new;
    List<Trip__c> oldTrips = Trigger.old;
    Map<Id, Trip__c> newTripsMap = Trigger.newMap;
    Map<Id, Trip__c> oldTripsMap = Trigger.oldMap;

    // ----------------------------------
    // Handler Call
    // ----------------------------------
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            TripTriggerHandler.beforeInsert(newTrips);
        } else if(Trigger.isUpdate){
            TripTriggerHandler.beforeUpdate(newTripsMap, oldTripsMap);
        }
    } else if(Trigger.isAfter){
        if(Trigger.isInsert){
            TripTriggerHandler.afterInsert(newTripsMap);
        } else if(Trigger.isUpdate){
            TripTriggerHandler.afterUpdate(newTripsMap, oldTripsMap);
        }
    }
}