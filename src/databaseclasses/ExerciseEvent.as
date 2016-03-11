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
package databaseclasses
{
	import mx.core.ClassFactory;
	
	import model.ModelLocator;
	
	import myComponents.ExerciseEventItemRenderer;
	import myComponents.IListElement;
	import myComponents.TrackingViewElement;
	
	public class ExerciseEvent extends TrackingViewElement implements IListElement
	{
		private var _level:String;

		public function get level():String
		{
			return _level;
		}

		private var _comment:String;

		public function get comment():String
		{
			return (_comment == null ? "":_comment);
		}
		
		private function set comment(value:String):void
		{
			_comment = value;
		}
		
		public function ExerciseEvent(level:String, newcomment:String, exerciseeventid:String,creationTimeStamp:Number = Number.NaN, newLastModifiedTimeStamp:Number = Number.NaN, storeInDatabase:Boolean = true)
		{
			this._level = level;
			this.eventid = exerciseeventid;
			this._comment = newcomment;
			if (!isNaN(creationTimeStamp))
				_timeStamp = creationTimeStamp;
			else
				_timeStamp = (new Date()).valueOf();
			
			if (!isNaN(newLastModifiedTimeStamp))
				lastModifiedTimestamp = newLastModifiedTimeStamp;
			else
				lastModifiedTimestamp = (new Date()).valueOf();
			
			if (storeInDatabase)
				Database.getInstance().createNewExerciseEvent(level,_comment,_timeStamp,lastModifiedTimestamp,exerciseeventid,null);
		}
		
		/**
		 * will update the exerciseevent in the database with the new values for level and comment and amount<br>
		 * if newComment = null then an empty string will be used<br>
		 */
		public function updateExerciseEvent(newLevel:String,newCreationTimeStamp:Number, newLastModifiedTimeStamp:Number,newComment:String = null):void {
			_level = newLevel;
			_comment = newComment;

				if (new Number(Settings.getInstance().getSetting(Settings.SettingsLastGoogleSyncTimeStamp)) > lastModifiedTimestamp)
					Settings.getInstance().setSetting(Settings.SettingsLastGoogleSyncTimeStamp,lastModifiedTimestamp.toString());
				lastModifiedTimestamp = newLastModifiedTimeStamp;
			
			if (!isNaN(newCreationTimeStamp))
				timeStamp = newCreationTimeStamp;
			Database.getInstance().updateExerciseEvent(this.eventid,newLevel,_comment, timeStamp,lastModifiedTimestamp);
		}

		public function listElementRendererFunction():ClassFactory
		{
			return new ClassFactory(ExerciseEventItemRenderer);
		}
		
		/**
		 * delete the event from the database<br>
		 * once deleted this event should not be used anymore
		 */
		override public function deleteEvent(trackingListPointer:Number = Number.NaN):void {
			if (isNaN(trackingListPointer))
				trackingListPointer = ModelLocator.trackingList.getItemIndex(this);
			ModelLocator.trackingList.removeItemAt(trackingListPointer);
			Database.getInstance().deleteExerciseEvent(this.eventid);
		}
	}
}