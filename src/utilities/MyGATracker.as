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
	import com.google.analytics.GATracker;
	
	import databaseclasses.Settings;
	
	import flash.display.DisplayObject;
	
	import mx.resources.ResourceManager;
	
	public class MyGATracker
	{
		private static var trackerId:String;
		
		private static var gaTracker:GATracker;
		
		private static var instance:MyGATracker;
		
		public function MyGATracker()
		{
			trackerId = ResourceManager.getInstance().getString('analytics','trackeraccount');
			if (instance != null) {
				throw new Error("MyGATracker class can only be accessed through MyGATracker.getInstance()");	
			}
			instance = this;
		}
		
		/**
		 * any display , can be null but then there should already have been a call to getinstance with a non-null display<br>
		 * should be a displayobject, but because I had cases here where a 'global object' was passed, i changed the type to object
		 */
		public static function getInstance(display:Object = null):MyGATracker {
			if (instance == null) 
					instance = new MyGATracker();

			if (gaTracker == null && display != null && display is DisplayObject) {
				try {
					gaTracker = new GATracker(display as DisplayObject, trackerId, "AS3", false, null, null);
					trace("gatracker successfuly created");
				} catch (error:Error) {
					//creation of gatracker failed, hopefully better luck next time
				}
			}
			
			return instance;
		}
		
		/**
		 * returns true if track launched 
		 */
		public function  trackPageview(pageURL:String=""):Boolean {
			if (gaTracker != null) {
				if ((new Date()).valueOf() - 7*24*60*60*1000 > new Number(Settings.getInstance().getSetting(Settings.SettingsFirstStartUp))) {
					gaTracker.trackPageview(pageURL);
					return true;
				}
			}
			return false;
		}
	}
}