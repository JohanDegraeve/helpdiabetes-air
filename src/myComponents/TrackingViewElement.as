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
package myComponents
{
	import utilities.DateTimeUtilities;

	/**
	 * a superclass for the object types that can be element in the trackingview<br>
	 *  it's just here to be able to create a getHeight and getWidth method in the TrackingViewElementItemRenderer, with a single parameter<br>
	 * also the eventid is defined here 
	 */
	public class TrackingViewElement
		
	{
		protected var _timeStamp:Number;

		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		public function set timeStamp(value:Number):void
		{
			_timeStamp = value;
		}
		
		public function TrackingViewElement()
		{
			_eventid = DateTimeUtilities.createEventId();
		}
		
		private var _eventid:String;
		
		public function get eventid():String
		{
			return _eventid;
		}
		
		public function set eventid(value:String):void
		{
			_eventid = value;
		}

		private var _mark:Boolean;

		/**
		 * used for instance by search in tracking list, if true then this element is in the result and to be shown for instance<br>
		 * in first place only to be used for mealevents, but could be used for anything, can also be used in itemrenderer
		 */
		public function get mark():Boolean
		{
			return _mark;
		}

		/**
		 * @private
		 */
		public function set mark(value:Boolean):void
		{
			_mark = value;
		}


	}
}