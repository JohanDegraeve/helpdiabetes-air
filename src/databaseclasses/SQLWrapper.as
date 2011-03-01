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
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	
	public class SQLWrapper
	{
		{
			public var responder:DatabaseResponder;
			public var statement:SQLStatement;
			public var result:SQLResult;
			
			// Called when a query is executed successfully or unsuccessfully. Usually called to dispatch events
			public var onResult:Function;
			public var onError:Function;
			
			// Removes event listeners for the garbage collector  
			public var cleanUp:Function; 
			
			public function SQLWrapper()
			{
			}
		}
	}
}