import { LightningElement, api, track } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import modal from "@salesforce/resourceUrl/customActionScreenModal";
import getTripDays from '@salesforce/apex/TripAssistantController.getTripDays';
import getActivitiesWithoutTripDays from '@salesforce/apex/TripAssistantController.getActivitiesWithoutTripDays';

export default class TripAssistant extends LightningElement {
    @api recordId;

    @track showSchedulingModal;

    @track schedulingHeaderTitle = 'Scheduling Assistant';
    @track bookingHeaderTitle = 'Booking Assistant';

    @track dayData;
    @track selectedDays;

    @track activityData;
    @track selectedActivities;

    @track scheduledData;
    @track selectedScheduled;

    @track calendarData;

    connectedCallback(){
        loadStyle(this, modal);
        //-----------------------------------------------------------------------
        // DEFAULT SETTINGS
        //-----------------------------------------------------------------------
        this.showSchedulingModal = true;
        this.recordTypeFilter = 'All';
        //-----------------------------------------------------------------------
        this.dayData = [];
        this.selectedDays = [];
        this.activityData = [];
        this.selectedActivities = [];
        this.scheduledData = [];
        this.selectedScheduled = [];
    }

    renderedCallback(){
        console.log('Rendered Callback Criteria Met: ');
        console.log(this.recordId && this.dayData.length == 0);
        if(this.recordId && this.dayData.length == 0){
            this.getData();
        }
    }

    getData(){
        getTripDays({tripId: this.recordId})
            .then(result => {
                if(result){
                    this.selectedDays = [];
                    this.dayData = [];
                    let resultList = [];
                    for(let tripDayRec of JSON.parse(result)){
                        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        let activitiesList = [];
                        for(let tripDayActivity of tripDayRec.Trip_Activities__r.records){
                            console.log(tripDayActivity.RecordType.Name);
                            let activityRec = {
                                id: tripDayActivity.Id, 
                                label: tripDayActivity.Name, 
                                duration: tripDayActivity.Duration_Hours__c == undefined ? '0h' : tripDayActivity.Duration_Hours__c + 'h', 
                                location: tripDayActivity.Area__c == undefined ? 'Area Unknown' : tripDayActivity.Area__c, 
                                selected: false,
                                recordTypeName: tripDayActivity.RecordType.Name,
                                hidden: false,
                                recommended: false
                            };
                            activitiesList.push(activityRec);
                        }
                        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        let dayRec = {
                            id: tripDayRec.Id, 
                            label: tripDayRec.Name, 
                            weekDay: tripDayRec.Day__c, 
                            location: tripDayRec.Location__c, 
                            selected: true, 
                            activities: activitiesList
                        };
                        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        resultList.push(dayRec);
                        this.selectedDays.push(dayRec.id);
                    }
                    this.dayData = resultList;
                } else {
                    this.dayData.push('No Data');
                }
            })
            .catch(error => {
                console.log('error :', error);
                this.dayData.push('Failure');
            })
        
        getActivitiesWithoutTripDays({tripId: this.recordId})
            .then(result => {
                if(result){
                    this.selectedActivities = [];
                    let resultList = [];
                    for(let tripActivityRec of JSON.parse(result)){
                        let activityRec = {
                            id: tripActivityRec.Id, 
                            label: tripActivityRec.Name, 
                            duration: tripActivityRec.Duration_Hours__c == undefined ? '0h' : tripActivityRec.Duration_Hours__c + 'h', 
                            location: tripActivityRec.Area__c == undefined ? 'Area Unknown' : tripActivityRec.Area__c, 
                            selected: true,
                            recordTypeName: tripActivityRec.RecordType.Name,
                            hidden: false,
                            recommended: false
                        };
                        resultList.push(activityRec);
                        this.selectedActivities.push(activityRec.id);
                    }
                    this.activityData = resultList;
                } else {
                    this.activityData.push('No Data');
                }
            })
            .catch(error => {
                console.log('error :', error);
                this.activityData.push('Failure');
            })
        
        let resultList = [];
        for(let iter = 6; iter <= 22; iter++){
            let label = iter > 12 ? iter % 12 : iter;
            let calendarRec = {
                id: iter, 
                label: label,  
                selected: false,
                booked: false
            };
            resultList.push(calendarRec);
        }
        this.calendarData = resultList;
    }

    //-----------------------------------------------------------------------
    // GET METHODS
    //-----------------------------------------------------------------------

    get headerTitle(){
        return (this.showSchedulingModal ? this.schedulingHeaderTitle : this.bookingHeaderTitle);
    }

    get disableMoveButtons(){
        if(this.selectedDays && (this.selectedActivities || this.selectedScheduled)){
            return (this.selectedDays.length != 1 || (this.selectedActivities.length == 0 && this.selectedScheduled.length == 0));
        } else {
            return true;
        }
    }

    get tabs() {
        const tabs = [];
        tabs.push({value: 'All', label: 'All'});
        tabs.push({value: 'Transportation', label: 'Transport'});
        tabs.push({value: 'Activity', label: 'Activity'});
        tabs.push({value: 'Meal', label: 'Meal'});
        return tabs;
    }

    //-----------------------------------------------------------------------
    // MODAL & TAB METHODS
    //-----------------------------------------------------------------------

    handleActiveTab(event){
        //event.target.value
        this.recordTypeFilter = event.target.value;

        let tempFilteredList = [];
        for(let activity of this.activityData){
            let tempActivity = activity;
            if(!this.recordTypeFilter.includes('All')){
                if(!activity.recordTypeName.includes(this.recordTypeFilter)){
                    tempActivity.hidden = true;
                } else {
                    tempActivity.hidden = false;
                }
            } else {
                tempActivity.hidden = false;
            }
            tempFilteredList.push(activity);
        }
        this.activityData = tempFilteredList;

        tempFilteredList = [];
        for(let activity of this.scheduledData){
            let tempActivity = activity;
            if(!this.recordTypeFilter.includes('All')){
                if(!activity.recordTypeName.includes(this.recordTypeFilter)){
                    tempActivity.hidden = true;
                } else {
                    tempActivity.hidden = false;
                }
            } else {
                tempActivity.hidden = false;
            }
            tempFilteredList.push(activity);
        }
        this.scheduledData = tempFilteredList;
    }

    handleActiveDayTab(event){
        console.log(event.target.value);
    }
    
    handleOpenBookingAssistant(){
        this.showSchedulingModal = false;
    }

    handleOpenSchedulingAssistant(){
        this.showSchedulingModal = true;
    }

    //-----------------------------------------------------------------------
    // SCHEDULING ASSISTANT - SELECTION HANDLERS
    //-----------------------------------------------------------------------

    handleScheduledActivitySelection(event){
        let newData = this.scheduledData;

        //ALL SELECTED
        if(this.selectedScheduled.length == newData.length){
            this.selectedScheduled = [];
        }

        let scheduledActivityId = event.target.dataset.id;
        for(let scheduledActivity of newData){
            if(scheduledActivity.id == scheduledActivityId){
                if(this.selectedScheduled.includes(scheduledActivityId)){
                    for( var iter = 0; iter < this.selectedScheduled.length; iter++){
                        if ( this.selectedScheduled[iter] == scheduledActivityId) { 
                            this.selectedScheduled.splice(iter, 1); 
                        }
                    }
                } else {
                    this.selectedScheduled.push(scheduledActivityId);
                }
            }
        }

        for(let scheduledActivity of newData){
            if(this.selectedScheduled.includes(String(scheduledActivity.id))){
                scheduledActivity.selected = true;
            } else {
                scheduledActivity.selected = false;
            }
        }

        this.scheduledData = newData;
    }
    
    handleActivitySelection(event){
        let newDayData = this.activityData;

        //ALL SELECTED
        if(this.selectedActivities.length == newDayData.length){
            this.selectedActivities = [];
        }

        let tripDayId = event.target.dataset.id;
        for(let tripDay of newDayData){
            if(tripDay.id == tripDayId){
                if(this.selectedActivities.includes(tripDayId)){
                    for( var iter = 0; iter < this.selectedActivities.length; iter++){
                        if ( this.selectedActivities[iter] == tripDayId) { 
                            this.selectedActivities.splice(iter, 1); 
                        }
                    }
                } else {
                    this.selectedActivities.push(tripDayId);
                }
            }
        }

        //NONE SELECTED
        if(this.selectedActivities.length == 0){
            for(let tripDay of newDayData){
                this.selectedActivities.push(String(tripDay.id));
            }
        }

        for(let tripDay of newDayData){
            if(this.selectedActivities.includes(String(tripDay.id))){
                tripDay.selected = true;
            } else {
                tripDay.selected = false;
            }
        }

        this.activityData = newDayData;
    }

    handleDaySelection(event){
        //console.log(event.target.textContent);
        //console.log(event.detail);

        let newDayData = this.dayData;

        //ALL SELECTED
        if(this.selectedDays.length == newDayData.length){
            this.selectedDays = [];
        }

        let tripDayId = event.target.dataset.id;
        for(let tripDay of newDayData){
            if(tripDay.id == tripDayId){
                if(this.selectedDays.includes(tripDayId)){
                    for( var iter = 0; iter < this.selectedDays.length; iter++){
                        if ( this.selectedDays[iter] == tripDayId) { 
                            this.selectedDays.splice(iter, 1); 
                        }
                    }
                } else {
                    this.selectedDays.push(tripDayId);
                }
            }
        }

        //NONE SELECTED
        if(this.selectedDays.length == 0){
            for(let tripDay of newDayData){
                this.selectedDays.push(String(tripDay.id));
            }
        }

        this.scheduledData = [];
        for(let tripDay of newDayData){
            if(this.selectedDays.includes(String(tripDay.id))){
                tripDay.selected = true;
                for(let iter = 0; iter < tripDay.activities.length; iter++){
                    this.scheduledData.push(tripDay.activities[iter]);
                }

                let tempActivityData = this.activityData;
                for(let activity of tempActivityData){
                    if(activity.location == tripDay.location){
                        activity.recommended = true;
                    }
                }
                this.activityData = tempActivityData;
            } else {
                tripDay.selected = false;
            }
        }

        this.dayData = newDayData;
    }

    //-----------------------------------------------------------------------
    // SCHEDULING ASSISTANT - ASSOCIATE ACTIVITY TO DAY
    //-----------------------------------------------------------------------

    handleAddActivity(){
        for(let tripDay of this.dayData){
            if(this.selectedDays.includes(String(tripDay.id))){

                //Associate to Trip Day
                //Add to Scheduled Column
                //Add to Selected Scheduled
                for(let tripActivity of this.activityData){
                    if(this.selectedActivities.includes(String(tripActivity.id))){
                        tripDay.activities.push(tripActivity);
                        this.scheduledData.push(tripActivity);
                        this.selectedScheduled.push(String(tripActivity.id));
                    }
                }

                //Remove from Activity Column
                //Remove from Selected Activity
                for(let tripActivity of this.scheduledData){
                    let tempActivityData = this.activityData;
                    for(var iter = 0; iter < tempActivityData.length; iter++){
                        if(tempActivityData[iter].id == tripActivity.id) { 
                            tempActivityData.splice(iter, 1); 
                        }
                    }
                    this.activityData = tempActivityData;

                    let tempSelectionData = this.selectedActivities;
                    for(var iter = 0; iter < tempSelectionData.length; iter++){
                        if(tempSelectionData[iter] == tripActivity.id) { 
                            tempSelectionData.splice(iter, 1); 
                        }
                    }
                    this.selectedActivities = tempSelectionData;
                }
            }
        }

        console.log(JSON.stringify(this.selectedActivities));
        console.log(JSON.stringify(this.selectedScheduled));
    }

    handleRemoveActivity(){
        for(let tripDay of this.dayData){
            if(this.selectedDays.includes(String(tripDay.id))){
                
                //Add to Activity Column
                //Add to Selected Activity
                for(let tripActivity of this.scheduledData){
                    if(this.selectedScheduled.includes(String(tripActivity.id))){
                        this.activityData.unshift(tripActivity);
                        this.selectedActivities.push(String(tripActivity.id));
                    }
                }

                //Disassociate from Trip Day
                //Remove from Scheduled Column
                //Remove from Selected Scheduled
                for(let tripActivity of this.activityData){
                    let tempActivityData = this.scheduledData;
                    for(var iter = 0; iter < tempActivityData.length; iter++){
                        if(tempActivityData[iter].id == tripActivity.id) { 
                            tempActivityData.splice(iter, 1); 
                        }
                    }
                    this.scheduledData = tempActivityData;

                    let tempSelectionData = this.selectedScheduled;
                    for(var iter = 0; iter < tempSelectionData.length; iter++){
                        if(tempSelectionData[iter] == tripActivity.id) { 
                            tempSelectionData.splice(iter, 1); 
                        }
                    }
                    this.selectedScheduled = tempSelectionData;

                    let tempTripDayActivities = tripDay.activities;
                    for(var iter = 0; iter < tempTripDayActivities.length; iter++){
                        if(tempTripDayActivities[iter].id == tripActivity.id) { 
                            tempTripDayActivities.splice(iter, 1); 
                        }
                    }
                    tripDay.activities = tempTripDayActivities;
                }
            }
        }

        console.log(JSON.stringify(this.selectedActivities));
        console.log(JSON.stringify(this.selectedScheduled));
    }

    //-----------------------------------------------------------------------
    // SCHEDULING ASSISTANT - SAVE
    //-----------------------------------------------------------------------

    handleSaveSchedule(){
        console.log(JSON.stringify(this.dayData));
    }

    //-----------------------------------------------------------------------
    // BOOKING ASSISTANT
    //-----------------------------------------------------------------------

    handleBookActivity(event){
        console.log(event.target.value);
    }
}