trigger TripAccommodationTrigger on Trip_Accommodation__c (before insert, before update, after insert, after update) {
    // ----------------------------------
    // Context Variables
    // ----------------------------------
    List<Trip_Accommodation__c> newAccommodations = Trigger.new;
    List<Trip_Accommodation__c> oldAccommodations = Trigger.old;
    Map<Id, Trip_Accommodation__c> newAccommodationsMap = Trigger.newMap;
    Map<Id, Trip_Accommodation__c> oldAccommodationsMap = Trigger.oldMap;

    // ----------------------------------
    // Handler Call
    // ----------------------------------
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            TripAccommodationTriggerHandler.beforeInsert(newAccommodations);
        } else if(Trigger.isUpdate){
            TripAccommodationTriggerHandler.beforeUpdate(newAccommodationsMap, oldAccommodationsMap);
        }
    } else if(Trigger.isAfter){
        if(Trigger.isInsert){
            TripAccommodationTriggerHandler.afterInsert(newAccommodationsMap);
        } else if(Trigger.isUpdate){
            TripAccommodationTriggerHandler.afterUpdate(newAccommodationsMap, oldAccommodationsMap);
        }
    }
}