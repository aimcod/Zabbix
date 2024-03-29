﻿
#use for history tables

#[datetime]$minDate = "2022-08-15 16:39:32" #history, history_str and history_uint
#[datetime]$minDate = "2022-11-09 04:58:49" #history_text

#[datetime]$minDate = "2022-10-10 16:16:14" #history_text lower
#[datetime]$minDate = "2022-10-07 07:26:55" #history_str lower
[datetime]$minDate = "2022-10-07 08:21:53" #history_uint lower


#[datetime]$minDate = "2022-10-07 08:21:53" #history lower


$currDate = get-date -Format "yyyy-MM-dd hh:mm:ss"
#[datetime]$currDate = "2022-12-31 16:39:32"

while ([datetime]$minDate -le [datetime]$currDate)
{

        if ($minDate.day -lt 10)
        {

        $unix_DayStampCorrection = "0"+$($minDate.AddDays(1).Day)

        $unix_daystamp = "0"+$minDate.Day
        
         if ($minDate.day -eq 9)
            {
             $unix_DayStampCorrection = $($minDate.AddDays(1).Day)

            }

        }

        else
        {
        $unix_DayStampCorrection = $minDate.AddDays(1).Day

        $unix_daystamp = $minDate.Day
        }

        if ($minDate.Month -lt 10)
        {
        $unix_MonthStampCorrection = "0"+$($minDate.Month)
        $unix_MonthStamp = "0"+$minDate.Month

        }

        else
        {
        $unix_MonthStampCorrection = $minDate.Month
        $unix_MonthStamp = $minDate.Month

        }

        if ($minDate.AddDays(1).Day -eq 1)
        {
        $unix_DayStampCorrection = "0"+$minDate.AddDays(1).Day

        $unix_MonthStampCorrection = $minDate.AddMonths(1).Month

        if ($minDate.Month -eq 12)
        {

        $unix_MonthStampCorrection = "0"+$minDate.AddMonths(1).Month
       
        }

        }

        if ($minDate.Month -lt 8)
        {
           
        Write-Host "PARTITION p$($minDate.Year)_$($unix_MonthStampCorrection)_$($unix_daystamp) VALUES LESS THAN (UNIX_TIMESTAMP(`"$($minDate.year)-$($unix_MonthStampCorrection)-$($unix_DayStampCorrection) 00:00:00`")) ENGINE = InnoDB,"
        }
        else
        {
         if ($minDate.Month -eq 12 -and $minDate.Day -eq 31 )
            {

             Write-Host "PARTITION p$($minDate.Year)_$($unix_MonthStamp)_$($unix_daystamp) VALUES LESS THAN (UNIX_TIMESTAMP(`"$($minDate.AddYears(1).year)-$($unix_MonthStampCorrection)-$($unix_DayStampCorrection) 00:00:00`")) ENGINE = InnoDB,"
            }
        Write-Host "PARTITION p$($minDate.Year)_$($unix_MonthStamp)_$($unix_daystamp) VALUES LESS THAN (UNIX_TIMESTAMP(`"$($minDate.year)-$($unix_MonthStampCorrection)-$($unix_DayStampCorrection) 00:00:00`")) ENGINE = InnoDB,"
        }

$mindate = $minDate.AddDays(1)
}