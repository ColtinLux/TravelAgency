import { LightningElement, api, track } from 'lwc';
import getTripCalendar from '@salesforce/apex/HouseholdTripCalendarController.getTripCalendar';

export default class HouseholdTripCalendar extends LightningElement {
    @api yearPaginationEnabled;
    @api recordId;

    @track isLoading;
    @track isExpanded;
    @track data;

    connectedCallback(){
        this.isLoading = true;
        console.log(this.recordId);
        if(this.recordId){
            this.getData();
        } else {
            //this.connectedCallback();
        }
    }

    getData(){
        getTripCalendar({recordId: this.recordId})
            .then(result => {
                //console.log(JSON.stringify(JSON.parse(result)));
                this.data = [JSON.parse(result)];
                console.log(this.data);
                this.isLoading = false;
            })
            .catch(error => {
                console.log('error :', error);
            })
    }

    handleExpand(){
        this.isExpanded = true;
    }

    handleContract(){
        this.isExpanded = false;
    }
}