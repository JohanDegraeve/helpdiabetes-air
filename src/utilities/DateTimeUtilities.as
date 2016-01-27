/**
 Copyright (C) 2013  hippoandfriends
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 */
package utilities
{
	public class DateTimeUtilities
	{
		private static var ALPHA_CHAR_CODES:Array = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
		public function DateTimeUtilities()
		{
		}
		
		/**
		 * returns a new Date object<br>
		 * use this when dtDate has been created with local time in ms, eg new Date(0) is 00:00 1970... local time, ie locally this could be UTC time -1<br>
		 * in that case returnvalue will be the exact UTC time
		 */
		public static function convertToUTC(dtDate:Date):Date{
			var returnValue:Date = new Date();
			returnValue.setTime(dtDate.getTime() + (dtDate.getTimezoneOffset() * 60000))
			return returnValue;
		}
		
		/**
		 * the opposite of convertToUTC
		 */
		public static function convertFromUTC(dtDate:Date):Date{
			var returnValue:Date = new Date();
			returnValue.setTime(dtDate.getTime() - (dtDate.getTimezoneOffset() * 60000))
			return returnValue;
		}
		
		public static function createEventId():String {
			var eventId:Array = new Array(24);
			var date:String = (new Date()).valueOf().toString();
			for (var i:int = 0; i < date.length; i++) {
				eventId[i] = date.charAt(i);
			}
			for (; i < eventId.length;i++) {
				eventId[i] = ALPHA_CHAR_CODES[Math.floor(Math.random() *  16)];
			}
			var returnValue:String = "";
			for (i = 0; i < eventId.length; i++)
				returnValue += eventId[i];
			return returnValue;
		}
		
		public static function randomRange(minNum:Number, maxNum:Number):Number {
			return (Math.floor(Math.random()*(maxNum - minNum + 1)) + minNum);
		}
		
		/**
		 * input = created_at date and time as created by nightscout in mongodb 
		 */
		public static function createDateFromNSCreatedAt(NSCreatedAt:String):Date {
			var date:String = NSCreatedAt.split("T")[0];
			var time:String = NSCreatedAt.split("T")[1];
			
			var year:Number = date.split("-")[0];
			var month:Number = date.split("-")[1] - 1;
			var day:Number = date.split("-")[2];
			
			var hour:Number = time.split(":")[0];
			var minute:Number = time.split(":")[1];
			var second:Number = (time.split(":")[2] as String).split(".")[0];
			var millisecondsecond:Number = (time.split(":")[2] as String).split(".")[1].substr(0,3);
			var returnvalue:Date = new Date(year,month,day,hour,minute,second,millisecondsecond);
			return convertFromUTC(new Date(year,month,day,hour,minute,second,millisecondsecond));
		}
		
		public static function createNSFormattedDateAndTime(dateAndTime:Date):String {
//				NSDateTimeFormatter.dateTimePattern = "yyyy-MM-ddTHH:mm:ss.SSSZ";
			var month:String = (dateAndTime.monthUTC + 1).toString().length < 2 ? "0" + (dateAndTime.monthUTC + 1).toString() : (dateAndTime.monthUTC.toString() + 1).toString();
			var hours:String = (dateAndTime.hoursUTC).toString().length < 2 ? "0" + (dateAndTime.hoursUTC).toString() : (dateAndTime.hoursUTC.toString()).toString();
			var minutes:String = (dateAndTime.minutesUTC).toString().length < 2 ? "0" + (dateAndTime.minutesUTC).toString() : (dateAndTime.minutesUTC.toString()).toString();
			var seconds:String = (dateAndTime.secondsUTC).toString().length < 2 ? "0" + (dateAndTime.secondsUTC).toString() : (dateAndTime.secondsUTC.toString()).toString();
			var milliseconds:String = (dateAndTime.millisecondsUTC).toString().length < 3 ? ((dateAndTime.secondsUTC).toString().length < 2 ? "00" + (dateAndTime.millisecondsUTC).toString() : "0" + (dateAndTime.millisecondsUTC).toString()) : (dateAndTime.millisecondsUTC).toString() ;
			var test:String =  dateAndTime.fullYearUTC + "-" + month + "-" + dateAndTime.dateUTC + "T" + hours + ":" + minutes + ":" + seconds + "."  + milliseconds + "Z";
				
			return test;
		}
	}
}