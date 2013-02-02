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
	/**
	 * a superclass for the object types that can be element in the trackingview<br>
	 *  it's just here to be able to create a getHeight and getWidth method in the TrackingViewElementItemRenderer, with a single parameter<br>
	 * also the eventid is defined here 
	 */
	public class TrackingViewElement
	{
		public function TrackingViewElement()
		{
		}
		
		private var _eventid:Number;
		
		public function get eventid():Number
		{
			return _eventid;
		}
		
		public function set eventid(value:Number):void
		{
			_eventid = value;
		}
		

	}
}