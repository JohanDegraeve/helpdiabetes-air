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
	import mx.core.ClassFactory;
	
	/**
	 * simpletextevent, which can be used in trackingview just to show a simple text message
	 */
	public class SimpleTextEvent extends TrackingViewElement implements IListElement
	{
		private var _message:String;

		public function get message():String
		{
			return _message;
		}

		public function set message(value:String):void
		{
			_message = value;
		}

		
		public function SimpleTextEvent(message:String)
		{
			super();
			_message = message;
			timeStamp = 0;
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(SimpleTextEventItemRenderer);
		}
	}
}