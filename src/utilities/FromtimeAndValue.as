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
	
	/**
	 * a class that can hold a from time<br>
	 * a value (decimal value)<br>
	 * <br>
	 * from time between 0 and 36 hours<br>
	 * <br>
	 * once created, value and from can't be modified anymore. This is because the class FromTimeandValueArrayCollection
	 * needs to be able to check the value of an element against other objects in the list, eg if percentage based, when adding 
	 * a new element, value of new element should be between value of two elements before and after. If we would allow to modify objects
	 * then the class FromTimeandValueArrayCollection would not be able anymore to control that. Now it's controlled through the addItem 
	 * in the arraycollection class<br>
	 */
	public class FromtimeAndValue
	{
		private var _from:int;//time in seconds
		public function get from():int {return _from;}
		private var _value:Number;
		
		private var _unit:String;
		
		public function get unit():String
		{
			return _unit;
		}
		
		public function get value():Number
		{
			return _value;
		}
		
		private var _editable:Boolean = true;
		
		/**
		 * get should only be used by the itemrenderer FromtimeAndValueItemRenderer<br>
		 * 
		 */
		public function get editable():Boolean
		{
			return _editable;
		}
		
		
		private var _deletable:Boolean = true;
		/**
		 * get should only be used by the itemrenderer FromtimeAndValueItemRenderer<br>
		 * 
		 */
		public function get deletable():Boolean
		{
			return _deletable;
		}
		
		private var _hasAddButton:Boolean = true;
		
		/**
		 * should it have an add button or not<br>
		 * If yes, an add button is shown in the itemrenderer, and treated in listview<br>
		 * It means a new item can be added after this one.
		 */
		public function get hasAddButton():Boolean
		{
			return _hasAddButton;
		}
		
		/**
		 * @private
		 */
		public function set hasAddButton(value:Boolean):void
		{
			_hasAddButton = value;
		}
		
		
		/**
		 * the fromtime in format hh:mm 
		 */
		public function fromAsString():String {
			//return _from.toString();;
			var minutes:Number = (Math.round(from % 3600/60));
			var hours:Number = Math.floor(from/3600);
			if (minutes == 60) {
				minutes = 0;
				hours++;
			}
			return (hours < 10 ? "0" + hours:hours) + ":" + (minutes < 10 ? "0" + minutes:minutes);
		}
		
		/**
		 * newFrom can be integer or Number, in which case it represents time in seconds ! (not in milliseconds)<br>
		 * or String, in which case it represents time in format HH:mm<br>
		 * <br>
		 * once created, value and from can't be modified anymore. This is because the class FromTimeandValueArrayCollection
		 * needs to be able to check the value of an element against other objects in the list, eg if percentage based, when adding 
		 * a new element, value of new element should be between value of two elements before and after. If we would allow to modify objects
		 * then the class FromTimeandValueArrayCollection would not be able anymore to control that. Now it's controlled through the addItem 
		 * in the arraycollection class<br>
		 */public function FromtimeAndValue(newFrom:Object,newValue:Number,newUnit:String,isEditable:Boolean,isDeletable:Boolean)
		 {
			 _editable = isEditable;
			 _deletable = isDeletable;
			 _unit = newUnit;
			 
			 if (newFrom is Number || newFrom is int)
				 _from = newFrom as Number;
			 else if (newFrom is String)
				 _from = ((new Number(newFrom.split(":")[0])) * 60 + (new Number(newFrom.split(":")[1])))*60;
			 else
				 throw new Error("error in FromtimeAndValue, newFrom should be Number, int or String");
			 
			 if (_from < 0 || _from > 129600000)
				 throw new Error("error in FromtimeAndValue, newFrom should be between 00:00 and 36:00 or between 0 and 129600");
			 _value = newValue;
		 }
	}
}