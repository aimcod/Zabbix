﻿
#use for trends tables

#[datetime]$minDate = "2022-06-09 10:00:00" #trends and trends_uint

[datetime]$minDate = "2022-06-01 06:00:00" #trends and trends_uint lower


$currDate = get-date -Format "yyyy-MM-dd hh:mm:ss"

while ([datetime]$minDate -le [datetime]$currDate)
{

<#
if ($minDate.day -lt 10)
{

$unix_DayStampCorrection = "0"+$($minDate.Day)

}
else
{
$unix_DayStampCorrection = $minDate.Day
}
#>

if ($minDate.Month -le 8)
{
$unix_MonthStampCorrection = "0"+$($minDate.AddMonths(1).Month)
$unix_MonthStamp = "0"+$($minDate.Month)

}
else
{
$unix_MonthStampCorrection = $minDate.AddMonths(1).Month
if ($minDate.Month -le 9)
{
$unix_MonthStamp = "0"+$minDate.Month
}
else
{
$unix_MonthStamp = $minDate.Month
}
}

if ($minDate.Month -eq 12)
{
Write-Host "PARTITION p$($minDate.Year)_$($unix_MonthStamp) VALUES LESS THAN (UNIX_TIMESTAMP(`"$($minDate.AddYears(1).Year)-01-01 00:00:00`")) ENGINE = InnoDB,"

}
else
{

Write-Host "PARTITION p$($minDate.Year)_$($unix_MonthStamp) VALUES LESS THAN (UNIX_TIMESTAMP(`"$($minDate.year)-$($unix_MonthStampCorrection)-01 00:00:00`")) ENGINE = InnoDB,"
}

$mindate = $minDate.AddMonths(1)
}