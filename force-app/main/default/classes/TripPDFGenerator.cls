// Author: Coltin Lappin-Lux
// Date: 9/20/2022

public without sharing class TripPDFGenerator{
    
    public static final String FORM_HTML_START = '<HTML><BODY>';
    public static final String FORM_HTML_END = '</BODY></HTML>';

    @AuraEnabled
    public static Id generateTripPDF(Id tripId){
        Id attachmentId = null;

        if(tripId == null){
            return attachmentId;
        }

        Trip__c tripRecord = [SELECT Id, Name, Location__c, Start_Date__c, End_Date__c, Status__c, Description__c, Start_Weekday__c, End_Weekday__c FROM Trip__c WHERE Id = :tripId];
        List<Trip_Day__c> tripDayList = [SELECT Id, Name, Status__c, Last_Day__c, Trip_Accommodation__c, Location__c, Date__c FROM Trip_Day__c WHERE Trip__c = :tripId ORDER BY Date__c];
        Map<Id, Trip_Day__c> tripDayMap = new Map<Id, Trip_Day__c>(tripDayList);
        List<Trip_Accommodation__c> accommodationList = [SELECT Id, Name, Status__c, Room_Description__c, Confirmation_Number__c, Accommodation_Address__c, Accommodation_Email__c, Accommodation_Phone__c, Check_In__c, Check_Out__c FROM Trip_Accommodation__c WHERE Trip__c = :tripId ORDER BY Check_In__c];
        Map<Id, Trip_Accommodation__c> accommodationMap = new Map<Id, Trip_Accommodation__c>(accommodationList);
        List<Trip_Activity__c> tripActivityList = [SELECT Id, Name, Status__c, End_Location__c, End_Time__c, End_Address__c, Start_Location__c, Start_Time__c, Start_Address__c, Identifier__c, Confirmation_Number__c, Date__c, RecordTypeId, RecordType.Name, Trip_Day__c, Website__c, Price__c, Notes__c FROM Trip_Activity__c WHERE Trip__c = :tripId ORDER BY Trip_Day__r.Date__c];

        String pdfContent = FORM_HTML_START;
        pdfContent = getHeader(pdfContent, tripRecord);
        pdfContent = getGeneralInformation(pdfContent, tripRecord);
        pdfContent = getBody(pdfContent, true, tripRecord, tripDayMap, tripActivityList, accommodationMap);
        pdfContent += FORM_HTML_END;
        pdfContent = removeNull(pdfContent);
        attachmentId = attachPDF(tripRecord, pdfContent);

        return attachmentId;
    }

    public static String getHeader(String pdfContent, Trip__c tripRecord){
        pdfContent += '<H2>' + tripRecord.Name + ' Travel Plan' + '</H2>';
        pdfContent += '<br>';
        pdfContent += '<P>' + 'Status: ' + tripRecord.Status__c + '</P>';
        pdfContent += '<br>';
        return pdfContent;
    }

    public static String getGeneralInformation(String pdfContent, Trip__c tripRecord){
        pdfContent += '---------------------------------------------------------------------------------------------------------------';
        pdfContent += '<H3>' + '1. General Information' + '</H3>';
        pdfContent += '---------------------------------------------------------------------------------------------------------------';
        pdfContent += '<br>';
        pdfContent += '<P>' + 'Destination: ' + tripRecord.Location__c + '</P>';
        pdfContent += '<br>';
        String startDate = tripRecord.Start_Date__c != null ? ', ' + Date.valueOf(tripRecord.Start_Date__c).format() : '';
        pdfContent += '<P>' + 'Start Date: ' + tripRecord.Start_Weekday__c + startDate + '</P>';
        String endDate = tripRecord.End_Date__c != null ? ', ' + Date.valueOf(tripRecord.End_Date__c).format() : '';
        pdfContent += '<P>' + 'End Date: ' + tripRecord.End_Weekday__c + endDate + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P>' + 'Budget: ' + 'TBD' + '</P>';
        pdfContent += '<P>' + 'Spent: ' + 'TBD' + '</P>';
        pdfContent += '<P>' + 'Remaining: ' + 'TBD' + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P>' + 'Notes: ' + tripRecord.Description__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<br>';
        return pdfContent;
    }

    public static String getBody(String pdfContent, Boolean useStatus, Trip__c tripRecord, Map<Id, Trip_Day__c> tripDayMap, List<Trip_Activity__c> tripActivityList, Map<Id, Trip_Accommodation__c> accommodationMap){
        if(useStatus){
            if(tripRecord.Status__c == 'Finalizing Dates'){
                return pdfContent;
            } else if(tripRecord.Status__c == 'Booking Transportation'){
                pdfContent = getTransportationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList);
            } else if(tripRecord.Status__c == 'Booking Accommodations'){
                pdfContent = getTransportationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList);
                pdfContent = getAccommodationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, accommodationMap);
            } else if(tripRecord.Status__c == 'Booking Activities'){
                pdfContent = getTransportationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList);
                pdfContent = getAccommodationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, accommodationMap);
                pdfContent = getDailyPlanInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, 'Activity');
            } else if(tripRecord.Status__c == 'Booking Restaurants'){
                pdfContent = getTransportationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList);
                pdfContent = getAccommodationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, accommodationMap);
                pdfContent = getDailyPlanInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, 'Activity');
                pdfContent = getDailyPlanInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, 'Meal');
            } else {
                pdfContent = getTransportationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList);
                pdfContent = getAccommodationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, accommodationMap);
                pdfContent = getDailyPlanInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, null);
            }
        } else {
            pdfContent = getTransportationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList);
            pdfContent = getAccommodationInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, accommodationMap);
            pdfContent = getDailyPlanInformation(pdfContent, tripRecord, tripDayMap, tripActivityList, null);
        }
        return pdfContent;
    }

    public static String getTransportationInformation(String pdfContent, Trip__c tripRecord, Map<Id, Trip_Day__c> tripDayMap, List<Trip_Activity__c> tripActivityList){
        pdfContent += '---------------------------------------------------------------------------------------------------------------';
        pdfContent += '<H3>' + '2. Transportation' + '</H3>';
        pdfContent += '---------------------------------------------------------------------------------------------------------------';
        pdfContent += '<br>';

        for(Trip_Activity__c activityRecord : tripActivityList){
            if(activityRecord.RecordType.Name == 'Transportation'){
                if(tripDayMap.containsKey(activityRecord.Trip_Day__c)){
                    Trip_Day__c tripDay = tripDayMap.get(activityRecord.Trip_Day__c);
                    pdfContent += '<P> ' + tripDay.Name + ': ' + Date.valueOf(tripDay.Date__c).format() + ' (' + tripDay.Location__c + ') </P>';
                } else {
                    pdfContent += '<P> Missing Trip Day </P>';
                }
                pdfContent += '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
                pdfContent = getTransporationFields(pdfContent, activityRecord);
                pdfContent += '<br>';
            }
        }

        return pdfContent;
    }

    public static String getAccommodationInformation(String pdfContent, Trip__c tripRecord, Map<Id, Trip_Day__c> tripDayMap, List<Trip_Activity__c> tripActivityList, Map<Id, Trip_Accommodation__c> accommodationMap){
        pdfContent += '---------------------------------------------------------------------------------------------------------------';
        pdfContent += '<H3>' + '3. Accommodations' + '</H3>';
        pdfContent += '---------------------------------------------------------------------------------------------------------------';
        pdfContent += '<br>';

        Set<Id> printedAccommodations = new Set<Id>();
        Set<Id> daysWithoutAccommodations = new Set<Id>();
        for(Trip_Day__c tripDayRecord : tripDayMap.values()){
            if(tripDayRecord.Trip_Accommodation__c == null && !tripDayRecord.Last_Day__c){
                daysWithoutAccommodations.add(tripDayRecord.Id);
            } else {
                Id accommodationId = tripDayRecord.Trip_Accommodation__c;
                if(!printedAccommodations.contains(accommodationId) && accommodationMap.containsKey(accommodationId)){
                    Trip_Accommodation__c accommodation = accommodationMap.get(accommodationId);
                    pdfContent += '<P> Accommodation: ' + accommodation.Name + '</P>';
                    pdfContent += '<P> Status: ' + accommodation.Status__c + '</P>';
                    pdfContent += '<br>';
                    pdfContent += '<P> Confirmation Number: ' + accommodation.Confirmation_Number__c + '</P>';
                    pdfContent += '<P> Room Description: ' + accommodation.Room_Description__c + '</P>';
                    pdfContent += '<P> Price: ' + 'TBD' + '</P>';
                    pdfContent += '<br>';
                    String checkIn = accommodation.Check_In__c != null ? accommodation.Check_In__c.format() : '';
                    pdfContent += '<P> Check-In: ' + checkIn + '</P>';
                    String checkOut = accommodation.Check_Out__c != null ? accommodation.Check_Out__c.format() : '';
                    pdfContent += '<P> Check-Out: ' + checkOut + '</P>';
                    pdfContent += '<br>';
                    pdfContent += '<P> Address: ' + accommodation.Accommodation_Address__c + '</P>';
                    pdfContent += '<P> Email: ' + accommodation.Accommodation_Email__c + '</P>';
                    pdfContent += '<P> Phone: ' + accommodation.Accommodation_Phone__c + '</P>';
                    pdfContent += '<br>';
                    pdfContent += '<br>';

                    printedAccommodations.add(accommodationId);
                }
            }
        }

        if(daysWithoutAccommodations.size() > 0){
            pdfContent += '<P> Days without Accommodations: </P>';
            for(Id tripDayId : daysWithoutAccommodations){
                Trip_Day__c tripDayRecord = tripDayMap.get(tripDayId);
                String dateValue = Date.valueOf(tripDayRecord.Date__c) != null ? Date.valueOf(tripDayRecord.Date__c).format() : '';
                pdfContent += '<P> ' + tripDayRecord.Name + ': ' + dateValue + ' (' + tripDayRecord.Location__c + ') </P>';
            }
            pdfContent += '<br>';
            pdfContent += '<br>';
        }

        return pdfContent;
    }

    public static String getDailyPlanInformation(String pdfContent, Trip__c tripRecord, Map<Id, Trip_Day__c> tripDayMap, List<Trip_Activity__c> tripActivityList, String recordType){
        pdfContent += '---------------------------------------------------------------------------------------------------------------';
        pdfContent += '<H3>' + '4. Daily Plan ' + recordType + '</H3>';
        pdfContent += '---------------------------------------------------------------------------------------------------------------';
        pdfContent += '<br>';

        Map<Id, List<Trip_Activity__c>> dayToActivityMap = new Map<Id, List<Trip_Activity__c>>();
        List<Trip_Activity__c> nonMappedActivityList = new List<Trip_Activity__c>();
        for(Trip_Activity__c activityRecord : tripActivityList){
            Id tripDayId = activityRecord.Trip_Day__c;
            if(tripDayId != null){
                List<Trip_Activity__c> activityList = dayToActivityMap.containsKey(tripDayId) ? dayToActivityMap.get(tripDayId) : new List<Trip_Activity__c>();
                activityList.add(activityRecord);
                dayToActivityMap.put(tripDayId, activityList);
            } else {
                nonMappedActivityList.add(activityRecord);
            }
        }

        for(Id tripDayId : dayToActivityMap.keySet()){
            Trip_Day__c tripDayRecord = tripDayMap.get(tripDayId);
            String dateValue = Date.valueOf(tripDayRecord.Date__c) != null ? Date.valueOf(tripDayRecord.Date__c).format() : '';
            pdfContent += '<P> ' + tripDayRecord.Name + ': ' + dateValue + ' (' + tripDayRecord.Location__c + ') </P>';
            pdfContent += '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';

            for(Trip_Activity__c activityRecord : dayToActivityMap.get(tripDayId)){
                if(recordType != null){
                    String thisRecordType = activityRecord.RecordType.Name;
                    if(thisRecordType == recordType && thisRecordType == 'Transportation'){
                        pdfContent = getTransporationFields(pdfContent, activityRecord);
                    } else if(thisRecordType == recordType && thisRecordType == 'Meal'){
                        pdfContent = getMealFields(pdfContent, activityRecord);
                    } else if(thisRecordType == recordType && thisRecordType == 'Activity'){
                        pdfContent = getActivityFields(pdfContent, activityRecord);
                    }
                } else {
                    String thisRecordType = activityRecord.RecordType.Name;
                    if(thisRecordType == 'Transportation'){
                        pdfContent = getTransporationFields(pdfContent, activityRecord);
                    } else if(thisRecordType == 'Meal'){
                        pdfContent = getMealFields(pdfContent, activityRecord);
                    } else {
                        pdfContent = getActivityFields(pdfContent, activityRecord);
                    }
                }
            }
        }

        if(nonMappedActivityList.size() > 0){
            pdfContent += '<P> Activities to Schedule </P>';
            pdfContent += '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
            for(Trip_Activity__c activityRecord : nonMappedActivityList){
                pdfContent += '<br>';
                pdfContent += '<P> ' + activityRecord.Name + '</P>';
                pdfContent += '=============================';
                pdfContent += '<br>';
                pdfContent += '<P> Status: ' + activityRecord.Status__c + '</P>';
                pdfContent += '<P> Confirmation Number: ' + activityRecord.Confirmation_Number__c + '</P>';
                pdfContent += '<P> Additional Info: ' + activityRecord.Identifier__c + '</P>';
                pdfContent += '<P> Website: ' + activityRecord.Website__c + '</P>';
                pdfContent += '<P> Price: ' + activityRecord.Price__c + '</P>';
                pdfContent += '<br>';
                pdfContent += '<P> Location: ' + activityRecord.Start_Location__c + '</P>';
                String startTime = activityRecord.Start_Time__c != null ? activityRecord.Start_Time__c.format() : '';
                pdfContent += '<P> Date/Time: ' + startTime + '</P>';
                pdfContent += '<P> Address: ' + activityRecord.Start_Address__c + '</P>';
                pdfContent += '<br>';
                pdfContent += '<P> Notes: ' + activityRecord.Notes__c + '</P>';
                pdfContent += '<br>';
                pdfContent += '<br>';
            }
        }

        return pdfContent;
    }

    public static String getTransporationFields(String pdfContent, Trip_Activity__c activityRecord){
        pdfContent += '<br>';
        pdfContent += '<P> Transport: ' + activityRecord.Name + '</P>';
        pdfContent += '=============================';
        pdfContent += '<br>';
        pdfContent += '<P> Status: ' + activityRecord.Status__c + '</P>';
        pdfContent += '<P> Confirmation Number: ' + activityRecord.Confirmation_Number__c + '</P>';
        pdfContent += '<P> Identifier (Flight Number): ' + activityRecord.Identifier__c + '</P>';
        pdfContent += '<P> Price: ' + activityRecord.Price__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P> Departure Location: ' + activityRecord.Start_Location__c + '</P>';
        String startTime = activityRecord.Start_Time__c != null ? activityRecord.Start_Time__c.format() : '';
        pdfContent += '<P> Departure Date/Time: ' + startTime + '</P>';
        pdfContent += '<P> Departure Address: ' + activityRecord.Start_Address__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P> Arrival Location: ' + activityRecord.End_Location__c + '</P>';
        String endTime = activityRecord.End_Time__c != null ? activityRecord.End_Time__c.format() : '';
        pdfContent += '<P> Arrival Date/Time: ' + endTime + '</P>';
        pdfContent += '<P> Arrival Address: ' + activityRecord.End_Address__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P> Notes: ' + activityRecord.Notes__c + '</P>';
        pdfContent += '<br>';
        return pdfContent;
    }

    public static String getMealFields(String pdfContent, Trip_Activity__c activityRecord){
        pdfContent += '<br>';
        pdfContent += '<P> Meal: ' + activityRecord.Name + '</P>';
        pdfContent += '=============================';
        pdfContent += '<br>';
        pdfContent += '<P> Status: ' + activityRecord.Status__c + '</P>';
        pdfContent += '<P> Confirmation Number: ' + activityRecord.Confirmation_Number__c + '</P>';
        pdfContent += '<P> Additional Info: ' + activityRecord.Identifier__c + '</P>';
        pdfContent += '<P> Website: ' + activityRecord.Website__c + '</P>';
        pdfContent += '<P> Price: ' + activityRecord.Price__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P> Location: ' + activityRecord.Start_Location__c + '</P>';
        String startTime = activityRecord.Start_Time__c != null ? activityRecord.Start_Time__c.format() : '';
        pdfContent += '<P> Date/Time: ' + startTime + '</P>';
        pdfContent += '<P> Address: ' + activityRecord.Start_Address__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P> Notes: ' + activityRecord.Notes__c + '</P>';
        pdfContent += '<br>';
        return pdfContent;
    }

    public static String getActivityFields(String pdfContent, Trip_Activity__c activityRecord){
        pdfContent += '<br>';
        pdfContent += '<P> Activity: ' + activityRecord.Name + '</P>';
        pdfContent += '=============================';
        pdfContent += '<br>';
        pdfContent += '<P> Status: ' + activityRecord.Status__c + '</P>';
        pdfContent += '<P> Confirmation Number: ' + activityRecord.Confirmation_Number__c + '</P>';
        pdfContent += '<P> Additional Info: ' + activityRecord.Identifier__c + '</P>';
        pdfContent += '<P> Website: ' + activityRecord.Website__c + '</P>';
        pdfContent += '<P> Price: ' + activityRecord.Price__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P> Start Location: ' + activityRecord.Start_Location__c + '</P>';
        String startTime = activityRecord.Start_Time__c != null ? activityRecord.Start_Time__c.format() : '';
        pdfContent += '<P> Start Date/Time: ' + startTime + '</P>';
        pdfContent += '<P> Start Address: ' + activityRecord.Start_Address__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P> End Location: ' + activityRecord.End_Location__c + '</P>';
        String endTime = activityRecord.End_Time__c != null ? activityRecord.End_Time__c.format() : '';
        pdfContent += '<P> End Date/Time: ' + endTime + '</P>';
        pdfContent += '<P> End Address: ' + activityRecord.End_Address__c + '</P>';
        pdfContent += '<br>';
        pdfContent += '<P> Notes: ' + activityRecord.Notes__c + '</P>';
        pdfContent += '<br>';
        return pdfContent;
    }

    public static String removeNull(String pdfContent){
        pdfContent = pdfContent.replace('null', '');
        return pdfContent;
    }

    public static Id attachPDF(Trip__c tripRecord, String pdfContent){
        Attachment attachmentPDF = new Attachment();
        attachmentPDF.parentId = tripRecord.Id;
        attachmentPDF.Name = tripRecord.Name + ' ' + DateTime.now().format() + '.pdf';
        attachmentPDF.body = Blob.toPDF(pdfContent); //This creates the PDF content
        insert attachmentPDF;
        return attachmentPDF.Id;
    }
}