/**
 Copyright (C) 2011  hippoandfriends
 
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
package myComponents
{
	import mx.core.ClassFactory;

	/**
	 * implements IListElement so has a timestamp and an listElementRendererFunction<br>
	 * can be added in an arraylist of meals or tracking events, will actually simple show a date in a color which is weekday dependent to 
	 * clearly show the weekends
	 */
	public class DayLine extends TrackingViewElement implements IListElement 
	{
		private var _timeStamp:Number;
		
		/**
		 * creates a dayline with timeStamp, time will be set to 00:00 in the morning 0 seconds 0 milliseconds 
		 */
		public function DayLine( timeStamp:Number)
		{
			this.timeStamp = timeStamp;
		}
		
		public function get timeStamp():Number {
			return _timeStamp
		}
		
		public function listElementRendererFunction ():ClassFactory {
			return new ClassFactory(DayLineItemRenderer);
		}

		
		/**
		 * sets thh timeStamp, time will be set to 00:00 in the morning 0 seconds 0 milliseconds , with 00:00 being local time<br>
		 * For instance if here in Belgium it is GMT+2, if timeStamp represents for example 5th of January 2011 at 10 o'clock, then timeStamp will be set to 4th of January at 22:00, which is the UTC time corresponding to 00:00 here in Belgium on 5th of January
		 */
		public function set timeStamp(value:Number):void
		{
			var newDate:Date = new Date(value);
			newDate.setHours(0,0,0,0);
			_timeStamp = newDate.valueOf();
		}
		
	}
}