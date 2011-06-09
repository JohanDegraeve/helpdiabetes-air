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
package myComponents
{
	import mx.core.ClassFactory;

	/**
	 * elements that are on the tracking view or on a meal list should implement that interface<br>
	 * it has a timeStamp, which will allow correct sorting in chronological order<br>
	 * and a an itemRenderer function, which will allow to correctly present the element in the tracking view<br>
	 * It can be used for any element, eg a bar that indicates a daty
	 */
	public interface IListElement
	{
		function get timeStamp():Number;
		
		function trackingItemRendererFunction ():ClassFactory;
	}
}