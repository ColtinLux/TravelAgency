// Author: Coltin Lappin-Lux
// Date: 9/20/2022

public without sharing class HouseholdTripCalendarController {
    @AuraEnabled
    public static String getTripCalendar(Id recordId, Boolean startWithCurrentMonth){
        Map<Date, String> dateList = new Map<Date, String>();
        for(Trip__c tripRecord : [SELECT Start_Date__c, End_Date__c, Status__c FROM Trip__c WHERE Account__c = :recordId]){
            Date currentDate = (Date) tripRecord.Start_Date__c;
            Date endDate = (Date) tripRecord.End_Date__c;
            while(currentDate <= endDate){
                dateList.put(currentDate, tripRecord.Status__c);
                currentDate = currentDate.addDays(1);
            }
        }

        //------------------------------------------------
        // Calendar Start
        //------------------------------------------------
        Date todayDate = Date.today();
        Integer thisYear = todayDate.year();
        Integer thisMonth = todayDate.month();
        Date currentDate = Date.newInstance(thisYear, 1, 1);
        if(startWithCurrentMonth){
            currentDate = Date.newInstance(thisYear, thisMonth, 1);
        }
        Datetime endDate = currentDate.addYears(1);
        Integer currentWeek = 1;

        CalendarYear yearRecord = new CalendarYear();
        yearRecord.year = thisYear;

        //------------------------------------------------
        // Constructing Calendar
        //------------------------------------------------
        Map<Integer, CalendarMonth> monthsMap = new Map<Integer, CalendarMonth>();
        Map<Integer, CalendarWeek> weeksMap = new Map<Integer, CalendarWeek>();
        Map<Integer, CalendarDay> daysMap = new Map<Integer, CalendarDay>();
        while(currentDate < endDate){
            Integer currentYear = currentDate.year();
            Integer currentMonthNumber = currentDate.month();
            Integer currentDayNumber = currentDate.day();
            Datetime currentDateTime = Datetime.newInstance(currentYear, currentMonthNumber, currentDayNumber, 0, 0, 0);
            String currentDay = currentDateTime.format('EEEE');

            if(currentDay.contains('Sunday')){
                currentWeek++;
                daysMap = new Map<Integer, CalendarDay>();
            } 
            
            if(!monthsMap.containsKey(currentMonthNumber)){
                weeksMap = new Map<Integer, CalendarWeek>();
                daysMap = new Map<Integer, CalendarDay>();
            }

            CalendarDay day = new CalendarDay();
            day.dayNumber = currentDate.day();
            day.dayOfYearNumber = currentDate.dayOfYear();
            day.weekDayName = currentDay;
            day.status = 'NA';
            if(currentDate == Date.today()){
                day.style = 'background-color: lightgrey;';
            } else if(dateList.containsKey(currentDate)){
                String status = dateList.get(currentDate);
                if(status.contains('New')){
                    day.style = 'background-color: red;';
                } else if(status.contains('Booked')){
                    day.style = 'background-color: lightgreen;';
                } else if(!status.contains('Cancelled')){
                    day.style = 'background-color: yellow;';
                }
            }
            daysMap.put(currentDayNumber, day);

            CalendarWeek week = weeksMap.containsKey(currentWeek) ? weeksMap.get(currentWeek) : new CalendarWeek();
            week.weekNumber = currentWeek;
            week.days = daysMap.values();
            weeksMap.put(currentWeek, week);

            CalendarMonth month = monthsMap.containsKey(currentMonthNumber) ? monthsMap.get(currentMonthNumber) : new CalendarMonth();
            month.monthName = currentDateTime.format('MMMM');
            month.monthNumber = currentMonthNumber;
            month.weeks = weeksMap.values();
            monthsMap.put(currentMonthNumber, month);
            yearRecord.months = monthsMap.values();

            Integer beforecurrentDayNumber = currentDate.day();
            if(daysMap.keySet().size()>6){
                System.debug('Before: ' + currentDate);
                System.debug('Before: ' + beforecurrentDayNumber);
            }

            currentDate = currentDate.addDays(1);
            Integer aftercurrentDayNumber = currentDate.day();

            if(daysMap.keySet().size()>6){
                System.debug('After: ' + currentDate);
                System.debug('After: ' + aftercurrentDayNumber);
                System.debug('---------------------------------');

                if(daysMap.keySet().size()>7){
                    for(CalendarDay key : daysMap.values()){
                        System.debug(key);
                    }
                }
            }
        }

        yearRecord.finalizeYear();

        return JSON.serialize(yearRecord);
    }

    public class CalendarYear {
        public Integer year;
        public List<CalendarMonth> months {get;set;}

        public CalendarYear(){
            this.months = new List<CalendarMonth>();
        }

        public void finalizeYear(){
            for(CalendarMonth month : this.months){
                month.finalizeMonth();
            }
        }
    }
    
    public class CalendarMonth {
        public Integer monthNumber {get;set;}
        public String monthName {get;set;}
        public List<CalendarWeek> weeks {get;set;}

        public CalendarMonth(){
            this.weeks = new List<CalendarWeek>();
        }

        public void finalizeMonth(){
            CalendarWeek week = this.weeks[0];
            List<CalendarDay> existingDays = week.days;
            Integer newLimit = 7 - existingDays.size();
            List<CalendarDay> newDays = new List<CalendarDay>();
            while(newDays.size() != newLimit){
                newDays.add(new CalendarDay());
            }
            week.days = new List<CalendarDay>();
            week.days.addAll(newDays);
            week.days.addAll(existingDays);

            Integer numOfWeeks = this.weeks.size();
            week = this.weeks[numOfWeeks-1];
            while(week.days.size() != 7){
                week.days.add(new CalendarDay());
            }
        }
    }

    public class CalendarWeek {
        public Integer weekNumber {get;set;}
        public List<CalendarDay> days {get;set;}

        public CalendarWeek(){
            this.days = new List<CalendarDay>();
        }
    }

    public class CalendarDay {
        public Integer dayNumber {get;set;}
        public Integer dayOfYearNumber {get;set;}
        public String weekDayName {get;set;}
        public String status {get;set;}
        public String style {get;set;}
    }
}