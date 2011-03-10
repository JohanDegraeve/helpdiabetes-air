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
/**
based on Survey Ape - Mobile on http://labs.adobe.com/technologies/flexsdk_hero/samples/
*/
package databaseclasses
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class DatabaseResponder extends EventDispatcher
	{
		{
			[Event(name="errorEvent",  type="database.DatabaseEvent")]
			[Event(name="resultEvent", type="database.DatabaseEvent")]
			
			public function DatabaseResponder()
			{
				
			}
		}
	}
}