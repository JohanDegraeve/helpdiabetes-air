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
package utilities
{
	import com.google.analytics.GATracker;
	import com.google.analytics.debug.DebugConfiguration;
	import com.google.analytics.v4.Configuration;
	
	import databaseclasses.Settings;
	
	import flash.display.DisplayObject;
	
	public class MyGATracker extends GATracker
	{
		public function MyGATracker(display:DisplayObject, account:String, mode:String="AS3", visualDebug:Boolean=false, config:Configuration=null, debug:DebugConfiguration=null)
		{
			super(display, account, mode, visualDebug, config, debug);
		}
		
		override public function  trackPageview(pageURL:String=""):void {
			if ((new Date()).valueOf() - 7*24*60*60*1000 > new Number(Settings.getInstance().getSetting(Settings.SettingsFirstStartUp))) 
				super.trackPageview(pageURL);
		}
	}
}