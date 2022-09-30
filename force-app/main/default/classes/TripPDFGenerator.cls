// Author: Coltin Lappin-Lux
// Date: 9/20/2022

public without sharing class TripPDFGenerator{
    
    public static final String FORM_HTML_START = '<HTML><BODY>';
    public static final String FORM_HTML_END = '</BODY></HTML>';

    //--------------------------------------------------------------------------------
    // MAIN METHODS
    //--------------------------------------------------------------------------------

    @AuraEnabled
    public static Id generateTripPDF(Id tripId){
        Id attachmentId = null;

        if(tripId == null){
            return attachmentId;
        }

        //-----------------------------------
        // Query Data
        //-----------------------------------
        Trip__c tripRecord = [SELECT Id, Name, Location__c, Start_Date__c, End_Date__c, Status__c, Description__c, Start_Weekday__c, End_Weekday__c FROM Trip__c WHERE Id = :tripId];
        List<Trip_Day__c> tripDayList = [SELECT Id, Name, Status__c, Last_Day__c, Trip_Accommodation__c, Location__c, Date__c FROM Trip_Day__c WHERE Trip__c = :tripId ORDER BY Date__c];
        Map<Id, Trip_Day__c> tripDayMap = new Map<Id, Trip_Day__c>(tripDayList);
        List<Trip_Accommodation__c> accommodationList = [SELECT Id, Name, Status__c, Room_Description__c, Confirmation_Number__c, Accommodation_Address__c, Accommodation_Email__c, Accommodation_Phone__c, Check_In__c, Check_Out__c FROM Trip_Accommodation__c WHERE Trip__c = :tripId ORDER BY Check_In__c];
        Map<Id, Trip_Accommodation__c> accommodationMap = new Map<Id, Trip_Accommodation__c>(accommodationList);
        List<Trip_Activity__c> tripActivityList = [SELECT Id, Name, Status__c, End_Location__c, End_Time__c, End_Address__c, Start_Location__c, Start_Time__c, Start_Address__c, Identifier__c, Confirmation_Number__c, Date__c, RecordTypeId, RecordType.Name, Trip_Day__c, Website__c, Price__c, Notes__c FROM Trip_Activity__c WHERE Trip__c = :tripId ORDER BY Trip_Day__r.Date__c];

        //-----------------------------------
        // Construct PDF
        //-----------------------------------
        String pdfContent = FORM_HTML_START;
        pdfContent = getHeader(pdfContent, tripRecord);
        pdfContent = getBody(pdfContent, true, tripRecord, tripDayMap, tripActivityList, accommodationMap);
        pdfContent += FORM_HTML_END;

        //-----------------------------------
        // Format PDF & Create Attachment
        //-----------------------------------
        pdfContent = removeNull(pdfContent);
        attachmentId = attachPDF(tripRecord, pdfContent);

        return attachmentId;
    }

    public static Id attachPDF(Trip__c tripRecord, String pdfContent){
        Attachment attachmentPDF = new Attachment();
        attachmentPDF.parentId = tripRecord.Id;
        attachmentPDF.Name = tripRecord.Name + ' ' + DateTime.now().format() + '.pdf';
        attachmentPDF.body = Blob.toPDF(pdfContent); //This creates the PDF content
        insert attachmentPDF;
        return attachmentPDF.Id;
    }

    //--------------------------------------------------------------------------------
    // HEADER
    //--------------------------------------------------------------------------------

    public static String getHeader(String pdfContent, Trip__c tripRecord){
        pdfContent += '<table border="1" cellpadding="10"><tr><td bgcolor="#f2f2f2">';

        pdfContent += '<table border="1" cellpadding="4" align="center"><tr><td bgcolor="#add8e6">';
        pdfContent += '<H2>' + tripRecord.Name + ' Travel Plan' + '</H2>';
        pdfContent += '</td></tr></table>';
        pdfContent += '<br>';

        Map<String, String> newMap = new Map<String, String>();
        newMap.put('Trip Status', tripRecord.Status__c);
        newMap.put('Trip Updated', DateTime.now().format());
        pdfContent = getTable(pdfContent, newMap);

        pdfContent += '</td></tr></table>';

        pdfContent += '<br>';
        pdfContent += '<br>';

        pdfContent = getGeneralInformation(pdfContent, tripRecord);

        return pdfContent;
    }

    public static String getGeneralInformation(String pdfContent, Trip__c tripRecord){
        pdfContent += '<table border="1" cellpadding="10"><tr><td bgcolor="#f2f2f2">';

        pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#b6d8d3">';
        pdfContent += 'General Information';
        pdfContent += '</td></tr></table>';

        pdfContent += '<br>';

        Map<String, String> newMap = new Map<String, String>();
        newMap.put('Destination', tripRecord.Location__c);
        String startDate = tripRecord.Start_Date__c != null ? ', ' + Date.valueOf(tripRecord.Start_Date__c).format() : '';
        newMap.put('Start Date', tripRecord.Start_Weekday__c + startDate);
        String endDate = tripRecord.End_Date__c != null ? ', ' + Date.valueOf(tripRecord.End_Date__c).format() : '';
        newMap.put('End Date', tripRecord.End_Weekday__c + endDate);
        pdfContent = getTable(pdfContent, newMap);

        pdfContent += '<br>';

        newMap = new Map<String, String>();
        newMap.put('Budget', 'TBD');
        newMap.put('Spent', 'TBD');
        newMap.put('Remainder', 'TBD');
        pdfContent = getTable(pdfContent, newMap);
        
        pdfContent += '<br>';

        pdfContent = getTable(pdfContent, 'Notes: ' + tripRecord.Description__c);

        pdfContent += '</td></tr></table>';

        pdfContent += '<br>';
        return pdfContent;
    }

    //--------------------------------------------------------------------------------
    // BODY
    //--------------------------------------------------------------------------------

    public static String getBody(String pdfContent, Boolean useStatus, Trip__c tripRecord, Map<Id, Trip_Day__c> tripDayMap, List<Trip_Activity__c> tripActivityList, Map<Id, Trip_Accommodation__c> accommodationMap){
        if(useStatus){
            if(tripRecord.Status__c == 'New' || tripRecord.Status__c == 'Finalizing Dates'){
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
        pdfContent += '<table border="1" cellpadding="10"><tr><td bgcolor="#f2f2f2">';

        pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#b6d8d3">';
        pdfContent += 'Transportation';
        pdfContent += '</td></tr></table>';

        for(Trip_Activity__c activityRecord : tripActivityList){
            if(activityRecord.RecordType.Name == 'Transportation'){
                pdfContent += '<br>';

                // Header
                pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#add8e6">';
                if(tripDayMap.containsKey(activityRecord.Trip_Day__c)){
                    Trip_Day__c tripDay = tripDayMap.get(activityRecord.Trip_Day__c);
                    pdfContent += tripDay.Name + ': ' + Date.valueOf(tripDay.Date__c).format() + ' (' + tripDay.Location__c + ')';
                } else {
                    pdfContent += 'Missing Trip Day';
                }
                pdfContent += '</td></tr></table>';

                // Body
                pdfContent = getTransporationFields(pdfContent, activityRecord);
            }
        }

        pdfContent += '</td></tr></table>';

        pdfContent += '<br>';

        return pdfContent;
    }

    public static String getAccommodationInformation(String pdfContent, Trip__c tripRecord, Map<Id, Trip_Day__c> tripDayMap, List<Trip_Activity__c> tripActivityList, Map<Id, Trip_Accommodation__c> accommodationMap){
        pdfContent += '<table border="1" cellpadding="10"><tr><td bgcolor="#f2f2f2">';
        
        pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#b6d8d3">';
        pdfContent += 'Accommodations';
        pdfContent += '</td></tr></table>';

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
                    pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#add8e6">';
                    pdfContent += '<P>' + accommodation.Name + '</P>';
                    pdfContent += '</td></tr></table>';

                    Map<String, String> newMap = new Map<String, String>();
                    newMap.put('Status', accommodation.Status__c);
                    newMap.put('Confirmation Number', accommodation.Confirmation_Number__c);
                    newMap.put('Room Description', accommodation.Room_Description__c);
                    newMap.put('Price', 'TBD');
                    pdfContent = getTable(pdfContent, newMap);

                    pdfContent += '<br>';

                    newMap = new Map<String, String>();
                    String checkIn = accommodation.Check_In__c != null ? accommodation.Check_In__c.format() : '';
                    newMap.put('Check-In', checkIn);
                    String checkOut = accommodation.Check_Out__c != null ? accommodation.Check_Out__c.format() : '';
                    newMap.put('Check-Out', checkOut);
                    pdfContent = getTable(pdfContent, newMap);

                    pdfContent += '<br>';

                    newMap = new Map<String, String>();
                    newMap.put('Address', accommodation.Accommodation_Address__c);
                    newMap.put('Email', accommodation.Accommodation_Email__c);
                    newMap.put('Phone', accommodation.Accommodation_Phone__c);
                    pdfContent = getTable(pdfContent, newMap);

                    pdfContent += '<br>';

                    printedAccommodations.add(accommodationId);
                }
            }
        }

        if(daysWithoutAccommodations.size() > 0){
            pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#add8e6">';
            pdfContent += '<P> Missing Accommodations </P>';
            pdfContent += '</td></tr></table>';

            for(Id tripDayId : daysWithoutAccommodations){
                Trip_Day__c tripDayRecord = tripDayMap.get(tripDayId);
                String dateValue = Date.valueOf(tripDayRecord.Date__c) != null ? Date.valueOf(tripDayRecord.Date__c).format() : '';
                pdfContent = getTable(pdfContent, tripDayRecord.Name + ': ' + dateValue + ' (' + tripDayRecord.Location__c + ')');
            }
        }

        pdfContent += '</td></tr></table>';

        pdfContent += '<br>';

        return pdfContent;
    }

    public static String getDailyPlanInformation(String pdfContent, Trip__c tripRecord, Map<Id, Trip_Day__c> tripDayMap, List<Trip_Activity__c> tripActivityList, String recordType){
        // Scheduled Activities vs NonScheduled Activities
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

        //Scheduled Activities
        for(Id tripDayId : dayToActivityMap.keySet()){
            pdfContent += '<table border="1" cellpadding="10"><tr><td bgcolor="#f2f2f2">';

            pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#b6d8d3">';
            pdfContent += 'Daily Plan ' + recordType;
            pdfContent += '</td></tr></table>';

            Trip_Day__c tripDayRecord = tripDayMap.get(tripDayId);

            pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#add8e6">';
            String dateValue = Date.valueOf(tripDayRecord.Date__c) != null ? Date.valueOf(tripDayRecord.Date__c).format() : '';
            pdfContent += tripDayRecord.Name + ': ' + dateValue + ' (' + tripDayRecord.Location__c + ')';
            pdfContent += '</td></tr></table>';

            for(Trip_Activity__c activityRecord : dayToActivityMap.get(tripDayId)){
                pdfContent += '<br>';
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

            pdfContent += '</td></tr></table>';
        }

        if(nonMappedActivityList.size() > 0){
            pdfContent += '<table border="1" cellpadding="10"><tr><td bgcolor="#f2f2f2">';

            pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#add8e6">';
            pdfContent += 'Activities to Schedule';
            pdfContent += '</td></tr></table>';

            for(Trip_Activity__c activityRecord : nonMappedActivityList){
                pdfContent = getActivityFields(pdfContent, activityRecord);
            }

            pdfContent += '</td></tr></table>';
        }

        return pdfContent;
    }

    public static String getTransporationFields(String pdfContent, Trip_Activity__c activityRecord){
        pdfContent += '<table border="1" cellpadding="4" bgcolor="#9FB5BE">';
        pdfContent += '<tr>';
        pdfContent += '<td>' + 'Transport' + '</td>';
        pdfContent += '<td>' + activityRecord.Name + '</td>';
        pdfContent += '</tr>';
        pdfContent += '</table>';

        Map<String, String> newMap = new Map<String, String>();
        newMap.put('Status', activityRecord.Status__c);
        newMap.put('Confirmation Number', activityRecord.Confirmation_Number__c);
        newMap.put('Identifier (Flight #)', activityRecord.Identifier__c);
        String price = activityRecord.Price__c != null ? activityRecord.Price__c.format() : '';
        newMap.put('Price', price);
        pdfContent = getTable(pdfContent, newMap);
        pdfContent = getTable(pdfContent, 'Notes: ' + activityRecord.Notes__c);

        pdfContent += '<br>';

        newMap = new Map<String, String>();
        newMap.put('Departure Location', activityRecord.Start_Location__c);
        String startTime = activityRecord.Start_Time__c != null ? activityRecord.Start_Time__c.format() : '';
        newMap.put('Departure Date/Time', startTime);
        newMap.put('Departure Address', activityRecord.Start_Address__c);
        pdfContent = getTable(pdfContent, newMap);

        pdfContent += '<br>';

        newMap = new Map<String, String>();
        newMap.put('Arrival Location', activityRecord.End_Location__c);
        String endTime = activityRecord.End_Time__c != null ? activityRecord.End_Time__c.format() : '';
        newMap.put('Arrival Date/Time', endTime);
        newMap.put('Arrival Address', activityRecord.End_Address__c);
        pdfContent = getTable(pdfContent, newMap);

        return pdfContent;
    }

    public static String getMealFields(String pdfContent, Trip_Activity__c activityRecord){
        pdfContent += '<table border="1" cellpadding="4" bgcolor="#9FB5BE">';
        pdfContent += '<tr>';
        pdfContent += '<td>' + 'Meal' + '</td>';
        pdfContent += '<td>' + activityRecord.Name + '</td>';
        pdfContent += '</tr>';
        pdfContent += '</table>';

        Map<String, String> newMap = new Map<String, String>();
        newMap.put('Status', activityRecord.Status__c);
        newMap.put('Confirmation Number', activityRecord.Confirmation_Number__c);
        newMap.put('Additional Info', activityRecord.Identifier__c);
        newMap.put('Website', activityRecord.Website__c);
        String price = activityRecord.Price__c != null ? activityRecord.Price__c.format() : '';
        newMap.put('Price', price);
        pdfContent = getTable(pdfContent, newMap);
        pdfContent = getTable(pdfContent, 'Notes: ' + activityRecord.Notes__c);

        pdfContent += '<br>';

        newMap = new Map<String, String>();
        newMap.put('Location', activityRecord.Start_Location__c);
        String startTime = activityRecord.Start_Time__c != null ? activityRecord.Start_Time__c.format() : '';
        newMap.put('Date/Time', startTime);
        newMap.put('Address', activityRecord.Start_Address__c);
        pdfContent = getTable(pdfContent, newMap);
        
        return pdfContent;
    }

    public static String getActivityFields(String pdfContent, Trip_Activity__c activityRecord){
        pdfContent += '<table border="1" cellpadding="4" bgcolor="#9FB5BE">';
        pdfContent += '<tr>';
        pdfContent += '<td>' + 'Activity' + '</td>';
        pdfContent += '<td>' + activityRecord.Name + '</td>';
        pdfContent += '</tr>';
        pdfContent += '</table>';

        Map<String, String> newMap = new Map<String, String>();
        newMap.put('Status', activityRecord.Status__c);
        newMap.put('Confirmation Number', activityRecord.Confirmation_Number__c);
        newMap.put('Additional Info', activityRecord.Identifier__c);
        newMap.put('Website', activityRecord.Website__c);
        String price = activityRecord.Price__c != null ? activityRecord.Price__c.format() : '';
        newMap.put('Price', price);
        pdfContent = getTable(pdfContent, newMap);
        pdfContent = getTable(pdfContent, 'Notes: ' + activityRecord.Notes__c);

        pdfContent += '<br>';

        newMap = new Map<String, String>();
        newMap.put('Start Location', activityRecord.Start_Location__c);
        String startTime = activityRecord.Start_Time__c != null ? activityRecord.Start_Time__c.format() : '';
        newMap.put('Start Date/Time', startTime);
        newMap.put('Start Address', activityRecord.Start_Address__c);
        pdfContent = getTable(pdfContent, newMap);

        pdfContent += '<br>';

        newMap = new Map<String, String>();
        newMap.put('End Location', activityRecord.End_Location__c);
        String endTime = activityRecord.End_Time__c != null ? activityRecord.End_Time__c.format() : '';
        newMap.put('End Date/Time', endTime);
        newMap.put('End Address', activityRecord.End_Address__c);
        pdfContent = getTable(pdfContent, newMap);

        return pdfContent;
    }

    //--------------------------------------------------------------------------------
    // HELPER METHODS
    //--------------------------------------------------------------------------------

    public static String getTable(String pdfContent, Map<String, String> dataMap){
        pdfContent += '<table border="1" cellpadding="4" bgcolor="#ffffff">';

        for(String key : dataMap.keySet()){
            String value = dataMap.get(key);
            pdfContent += '<tr>';
            pdfContent += '<td>' + key + '</td>';
            pdfContent += '<td>' + value + '</td>';
            pdfContent += '</tr>';
        }
        
        pdfContent += '</table>';

        return pdfContent;
    }

    public static String getTable(String pdfContent, String content){
        pdfContent += '<table border="1" cellpadding="4"><tr><td bgcolor="#ffffff">';
        pdfContent += content;
        pdfContent += '</td></tr></table>';

        return pdfContent;
    }

    public static String removeNull(String pdfContent){
        pdfContent = pdfContent.replace('null', '');
        return pdfContent;
    }
}