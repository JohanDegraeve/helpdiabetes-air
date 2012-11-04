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
		
		public function ExerciseEvent(level:String,comment:String, exerciseeventid:Number,creationTimeStamp:Number = Number.NaN, newLastModifiedTimeStamp:Number = Number.NaN, storeInDatabase:Boolean = true)
		{
			this._level = level;
			this.eventid = exerciseeventid;
			this._comment = comment;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			
			if (!isNaN(newLastModifiedTimeStamp))
				_lastModifiedTimestamp = newLastModifiedTimeStamp;
			else
				_lastModifiedTimestamp = (new Date()).valueOf();
			
			if (storeInDatabase)
				Database.getInstance().createNewExerciseEvent(level,comment,_timeStamp,_lastModifiedTimestamp,exerciseeventid,null);
		}
		
		public function get timeStamp():Number
		{
			return _timeStamp;
		}
		
		public function set timeStamp(newTimeStamp:Number):void
		{
			 _timeStamp = newTimeStamp;
		}
		
		private var _lastModifiedTimestamp:Number;
		
		public function get lastModifiedTimestamp():Number
		{
			return _lastModifiedTimestamp;
		}
		
		internal function set lastModifiedTimestamp(value:Number):void
		{
			_lastModifiedTimestamp = value;
		}
		
		/**
		 * will update the exerciseevent in the database with the new values for level and comment and amount<br>
		 * if newComment = null then an empty string will be used<br>
		 * if creationTimeStamp = null, then current date and time is used<br>
		 * if newLastModifiedTimestamp = null, then current date and time is used
		 */
		public function updateExerciseEvent(newLevel:String,newComment:String = null,newCreationTimeStamp:Number = Number.NaN, newLastModifiedTimeStamp:Number = Number.NaN):void {
			_level = newLevel;
			_comment = (newComment == null ? "":newComment);

			if (!isNaN(newLastModifiedTimeStamp)) {
				if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastSyncTimeStamp)) > _lastModifiedTimestamp)
					Settings.getInstance().setSetting(Settings.SettingsLastSyncTimeStamp,_lastModifiedTimestamp.toString());
				_lastModifiedTimestamp = newLastModifiedTimeStamp;
			}
			
			if (!isNaN(newCreationTimeStamp))
				timeStamp = newCreationTimeStamp;
			Database.getInstance().updateExerciseEvent(this.eventid,newLevel,_comment, timeStamp,_lastModifiedTimestamp);
		}

		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(ExerciseEventItemRenderer);
		}
		
		/**
		 * delete the event from the database<br>
		 * once delted this event should not be used anymore
		 */
		public function deleteEvent():void {
			Database.getInstance().deleteExerciseEvent(this.eventid);
		}
	}
}