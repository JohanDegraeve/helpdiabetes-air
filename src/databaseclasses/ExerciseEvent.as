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

		private var _eventid:Number;
		
		internal function get eventid():Number
		{
			return _eventid;
		}
		
		internal function set eventid(value:Number):void
		{
			_eventid = value;
		}

		private var _comment:String;

		public function get comment():String
		{
			return _comment;
		}
		
		public function ExerciseEvent(level:String,comment:String,creationTimeStamp:Number = NaN, storeInDatabase:Boolean = true, exerciseeventid:Number = NaN)
		{
			this._level = level;
			this.eventid = exerciseeventid;
			this._comment = comment;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			
			if (storeInDatabase)
				Database.getInstance().createNewExerciseEvent(level,comment,_timeStamp,null,exerciseeventid);
		}
		
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		public function set timeStamp(newTimeStamp:Number):void
		{
			 _timeStamp = newTimeStamp;
		}
		
		/**
		 * will update the exerciseevent in the database with the new values for level and comment and amount<br>
		 * if newComment = null then an empty string will be used
		 * if newCreationTimeStamp = null or Number.NaN then (creation)timeStamp is not updated
		 */
		public function updateExerciseEvent(newLevel:String,newComment:String = null,newCreationTimeStamp:Number = Number.NaN):void {
			_level = newLevel;
			_comment = (newComment == null ? "":newComment);
			if (!isNaN(newCreationTimeStamp))
				timeStamp = newCreationTimeStamp;
			Database.getInstance().updateExerciseEvent(this.eventid,newLevel,_comment, timeStamp);
		}

		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(ExerciseEventItemRenderer);
		}
	}
}