import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import generateTripPDF from '@salesforce/apex/TripPDFGenerator.generateTripPDF';

export default class TripPDFGenerator extends NavigationMixin(LightningElement) {
    @api recordId;
    @track attachmentId;

    @api async invoke() {
        this.createPDF(this.recordId);
    }

    connectedCallback(){
        console.log(this.recordId);
    }

    createPDF(recordIdValue){
        console.log(recordIdValue);
        generateTripPDF({tripId: recordIdValue})
            .then(result => {
                console.log(result);
                this.attachmentId = result;
                if(this.attachmentId){
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.attachmentId,
                            objectApiName: 'Attachment',
                            actionName: 'view'
                        },
                    });
                }
                console.log('CHECK FILES');
            })
            .catch(error => {
                console.log('error :', error);
            })
    }
}