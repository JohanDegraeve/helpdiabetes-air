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
		
		public function DayLine( timeStamp:Number)
		{
			this._timeStamp = timeStamp;
		}
		
		public function get timeStamp():Number {
			return _timeStamp
		}
		
		public function listElementRendererFunction ():ClassFactory {
			return new ClassFactory(DayLineItemRenderer);
		}

		public function set timeStamp(value:Number):void
		{
			_timeStamp = value;
		}
		
	}
}