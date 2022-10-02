import { LightningElement, api, track } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import modal from "@salesforce/resourceUrl/customActionScreenModal";
import getTripDays from '@salesforce/apex/TripAssistantController.getTripDays';
import getActivitiesWithoutTripDays from '@salesforce/apex/TripAssistantController.getActivitiesWithoutTripDays';
import saveSchedule from '@salesforce/apex/TripAssistantController.saveSchedule';

export default class TripAssistant extends NavigationMixin(LightningElement) {
    @api recordId;

    @track showSchedulingModal;
    @track showBookedModal;

    @track schedulingHeaderTitle = 'Scheduling Assistant';
    @track bookingHeaderTitle = 'Booking Assistant';

    @track dayData;
    @track selectedDays;

    @track activityData;
    @track selectedActivities;

    @track scheduledData;
    @track selectedScheduled;

    @track calendarData;
    @track currentCalendarData;

    @track activeDayTab;
    @track loadingBookingAssistant;

    connectedCallback(){
        loadStyle(this, modal);
        //-----------------------------------------------------------------------
        // DEFAULT SETTINGS
        //-----------------------------------------------------------------------
        this.showSchedulingModal = true;
        this.showBookedModal = false;
        this.recordTypeFilter = 'All';
        this.loadingBookingAssistant = false;
        //-----------------------------------------------------------------------
        this.dayData = [];
        this.selectedDays = [];
        this.activityData = [];
        this.selectedActivities = [];
        this.scheduledData = [];
        this.selectedScheduled = [];
    }

    renderedCallback(){
        //console.log('Rendered Callback Criteria Met: ');
        //console.log(this.recordId && this.dayData.length == 0);
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
                    this.scheduledData = [];
                    let resultList = [];
                    for(let tripDayRec of JSON.parse(result)){
                        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        let activitiesList = [];
                        if(tripDayRec.Trip_Activities__r && tripDayRec.Trip_Activities__r.records){
                            for(let tripDayActivity of tripDayRec.Trip_Activities__r.records){
                                let activityRec = {
                                    id: tripDayActivity.Id, 
                                    label: tripDayActivity.Name, 
                                    duration: tripDayActivity.Duration_Hours__c == undefined ? '0h' : tripDayActivity.Duration_Hours__c + 'h', 
                                    location: tripDayActivity.Area__c == undefined ? 'Area Unknown' : tripDayActivity.Area__c, 
                                    status: tripDayActivity.Status__c,
                                    startTime: tripDayActivity.Start_Time__c,
                                    endTime: tripDayActivity.End_Time__c,
                                    selected: false,
                                    recordTypeName: tripDayActivity.RecordType.Name,
                                    hidden: false,
                                    recommended: false
                                };
                                activitiesList.push(activityRec);
                                this.scheduledData.push(activityRec);
                            }
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
                            status: tripActivityRec.Status__c,
                            startTime: tripActivityRec.Start_Time__c,
                            endTime: tripActivityRec.End_Time__c,
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
    }

    resetData(currentTab){
        getTripDays({tripId: this.recordId})
            .then(result => {
                if(result){
                    this.selectedDays = [];
                    this.dayData = [];
                    this.scheduledData = [];
                    let resultList = [];
                    for(let tripDayRec of JSON.parse(result)){
                        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        let activitiesList = [];
                        if(tripDayRec.Trip_Activities__r && tripDayRec.Trip_Activities__r.records){
                            for(let tripDayActivity of tripDayRec.Trip_Activities__r.records){
                                let activityRec = {
                                    id: tripDayActivity.Id, 
                                    label: tripDayActivity.Name, 
                                    duration: tripDayActivity.Duration_Hours__c == undefined ? '0h' : tripDayActivity.Duration_Hours__c + 'h', 
                                    location: tripDayActivity.Area__c == undefined ? 'Area Unknown' : tripDayActivity.Area__c, 
                                    status: tripDayActivity.Status__c,
                                    startTime: tripDayActivity.Start_Time__c,
                                    endTime: tripDayActivity.End_Time__c,
                                    selected: false,
                                    recordTypeName: tripDayActivity.RecordType.Name,
                                    hidden: false,
                                    recommended: false
                                };
                                activitiesList.push(activityRec);
                                this.scheduledData.push(activityRec);
                            }
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
                    this.loadingBookingAssistant = false;
                    this.activeDayTab = currentTab;
                    this.resetCalendar(currentTab);
                } else {
                    this.dayData.push('No Data');
                }
            })
            .catch(error => {
                console.log('error :', error);
                this.dayData.push('Failure');
            })
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
        //console.log(event.target.value);
        let tripDayId = event.target.value;
        this.activeDayTab = tripDayId;
        this.resetCalendar(tripDayId);
    }

    resetCalendar(tripDayId){
        this.currentCalendarData = [];
        this.calendarData = [];

        let result = [];
        for(let tripDay of this.dayData){
            if(tripDay.id == tripDayId){
                let bookedBlocks = [];
                for(let tripActivity of tripDay.activities){
                    if(tripActivity.status == 'Booked'){
                        var start = new Date(tripActivity.startTime);
                        let startHour = start.getHours();
                        var end = new Date(tripActivity.endTime);
                        let endHour = end.getHours();
                        let iter = startHour;
                        while(iter < endHour){
                            bookedBlocks.push(iter);
                            iter++;
                        }
                    } else {
                        result.push(tripActivity);
                    }
                }

                let resultList = [];
                for(let iter = 6; iter <= 22; iter++){
                    let label = iter > 12 ? iter % 12 : iter;
                    let calendarRec = {
                        id: iter, 
                        label: label,  
                        selected: false,
                        booked: bookedBlocks.includes(iter)
                    };
                    resultList.push(calendarRec);
                }
                this.calendarData = resultList;
            }
        }
        this.currentCalendarData = result;
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

        //console.log(JSON.stringify(this.selectedActivities));
        //console.log(JSON.stringify(this.selectedScheduled));
    }

    handleRemoveActivity(){
        for(let tripDay of this.dayData){
            if(this.selectedDays.includes(String(tripDay.id))){
                
                //Add to Activity Column
                //Add to Selected Activity
                for(let tripActivity of this.scheduledData){
                    if(this.selectedScheduled.includes(String(tripActivity.id))){
                        if(tripActivity.status == 'Booked'){
                            const evt = new ShowToastEvent({
                                title: 'Error',
                                message: tripActivity.label + ' Activity is Booked. Cancel Booking Before Removing from Schedule.',
                                variant: 'error',
                            });
                            this.dispatchEvent(evt);
                        } else {
                            this.activityData.unshift(tripActivity);
                            this.selectedActivities.push(String(tripActivity.id));
                        }
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

        //console.log(JSON.stringify(this.selectedActivities));
        //console.log(JSON.stringify(this.selectedScheduled));
    }

    //-----------------------------------------------------------------------
    // SCHEDULING ASSISTANT - SAVE
    //-----------------------------------------------------------------------

    handleSaveSchedule(){
        let result = [];
        for(let tripDay of this.dayData){
            for(let tripActivity of tripDay.activities){
                let saveRec = {
                    Id: tripActivity.id,
                    Trip_Day__c: tripDay.id
                };
                result.push(saveRec);
            }
        }
        //console.log(result);

        saveSchedule({tripId: this.recordId, data: JSON.stringify(result)})
            .then(result => {
                if(result){
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'Schedule Saved.',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                } else {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Schedule could not be saved.',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
            })
            .catch(error => {
                console.log('error :', error);
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Schedule could not be saved.',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            })
    }

    //-----------------------------------------------------------------------
    // BOOKING ASSISTANT
    //-----------------------------------------------------------------------

    handleBookActivity(event){
        this.showBookedModal = true;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.value,
                objectApiName: 'Trip_Activity',
                actionName: 'edit'
            },
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    handleCancelBooking(){
        this.showBookedModal = false;
    }

    handleConfirmedBooking(){
        const currentTab = this.activeDayTab;
        this.loadingBookingAssistant = true;
        this.showBookedModal = false;
        this.resetData(currentTab);
    }
}