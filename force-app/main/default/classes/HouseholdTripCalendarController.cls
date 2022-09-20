public without sharing class HouseholdTripCalendarController {
    @AuraEnabled
    public static String getTripCalendar(Id recordId){
        List<Date> dateList = new List<Date>();
        for(Trip__c tripRecord : [SELECT Start_Date__c, End_Date__c FROM Trip__c WHERE Account__c = :recordId]){
            Date currentDate = (Date) tripRecord.Start_Date__c;
            Date endDate = (Date) tripRecord.End_Date__c;
            while(currentDate <= endDate){
                dateList.add(currentDate);
                currentDate = currentDate.addDays(1);
            }
        }
        System.debug(dateList);

        Datetime todayDate = Datetime.now();
        Integer thisYear = todayDate.year();
        Datetime currentDate = Datetime.newInstance(thisYear, 1, 1, 0, 0, 0);
        Datetime endDate = Datetime.newInstance(thisYear+1, 1, 1, 0, 0, 0);
        Integer currentWeek = 1;

        CalendarYear yearRecord = new CalendarYear();
        yearRecord.year = thisYear;

        Map<Integer, CalendarMonth> monthsMap = new Map<Integer, CalendarMonth>();
        Map<Integer, CalendarWeek> weeksMap = new Map<Integer, CalendarWeek>();
        Map<Integer, CalendarDay> daysMap = new Map<Integer, CalendarDay>();
        while(currentDate < endDate){
            Integer currentMonthNumber = currentDate.month();
            Integer currentDayNumber = currentDate.day();
            String currentDay = currentDate.format('EEEE');

            if(currentDay == 'Sunday'){
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
            Date converstion = Date.newInstance(thisYear, currentMonthNumber, currentDayNumber);
            if(dateList.contains(converstion)){
                day.style = 'background-color: lightblue;';
            }
            daysMap.put(currentDayNumber, day);

            CalendarWeek week = weeksMap.containsKey(currentWeek) ? weeksMap.get(currentWeek) : new CalendarWeek();
            week.weekNumber = currentWeek;
            week.days = daysMap.values();
            weeksMap.put(currentWeek, week);

            CalendarMonth month = monthsMap.containsKey(currentMonthNumber) ? monthsMap.get(currentMonthNumber) : new CalendarMonth();
            month.monthName = currentDate.format('MMMM');
            month.monthNumber = currentMonthNumber;
            month.weeks = weeksMap.values();
            monthsMap.put(currentMonthNumber, month);
            yearRecord.months = monthsMap.values();

            currentDate = currentDate.addDays(1);
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
