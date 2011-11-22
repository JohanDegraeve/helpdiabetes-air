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
package databaseclasses
{
	import mx.core.ClassFactory;
	
	import myComponents.ExerciseEventItemRenderer;
	import myComponents.IListElement;
	import myComponents.TrackingViewElement;
	
	public class ExerciseEvent extends TrackingViewElement implements IListElement
	{
		private var _timeStamp:Number;

		private var _level:String;

		public function get level():String
		{
			return _level;
		}

		private var _comment:String;

		public function get comment():String
		{
			return _comment;
		}
		
		public function ExerciseEvent(level:String,comment:String,creationTimeStamp:Number = NaN, storeInDatabase:Boolean = true)
		{
			this._level = level;
			this._comment = comment;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			
			if (storeInDatabase)
				Database.getInstance().createNewExerciseEvent(level,comment,_timeStamp,null);
		}
		
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(ExerciseEventItemRenderer);
		}
	}
}