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
	import databaseclasses.Meal;
	import databaseclasses.MealEvent;
	
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import model.ModelLocator;
	
	import mx.collections.IList;
	import mx.core.ClassFactory;
	import mx.core.ILayoutElement;
	
	import spark.components.DataGroup;
	import spark.components.supportClasses.GroupBase;
	import spark.layouts.BasicLayout;
	import spark.layouts.VerticalLayout;
	
	public class TrackingViewLayout extends BasicLayout {
		
		private var _lastIndexInView:int;
		private var _firstIndexInView:int;
		private var yToIndex:Vector.<int>; 
		private var indexToY:Vector.<int>; 
		private var _currentFirstIndexInView:int;
		private var _currentLastIndexInView:int;
		private var _firstUpdateDisplayList:Boolean=true;
		
		
		/**
		 * 
		 */ 
		override public function measure():void {
			var layoutTarget:GroupBase = target;
			if (!layoutTarget)
				return;
			var dataGroupTarget:DataGroup = layoutTarget as DataGroup;
			
			var totalHeight:Number = 0;
			var dataProvider:IList = dataGroupTarget.dataProvider;
			if (!dataProvider || !dataProvider.length)
				return;
			var count:int = dataProvider.length;
			
			var elementHeight:Number;
			yToIndex = new Vector.<int>();
			indexToY = new Vector.<int>();
			var d:Object ;
			//loop though all the elements elements
			for (var i:int = 0; i < count; i++) {
				d = dataProvider.getItemAt(i);
				elementHeight = ((d as IListElement).listElementRendererFunction().newInstance() as TrackingViewElementItemRenderer).getHeight((d as TrackingViewElement)) ;
				//add the index to vector
				addToVectorY(i, totalHeight /* + 1*/, elementHeight);//I'm not adding the 1 here because I'm also not doing that in the getHeight method in the itemrenderer, meaning the elements overlap with one pixel height
				totalHeight += elementHeight ;
				addToVectorIndex(i, totalHeight - elementHeight );
			}
			//just adding one element because I use this last value to calculate the size of the really last element (ie the max-1 array element) in method updatevirtual
			addToVectorIndex(i,totalHeight);
			
			layoutTarget.measuredWidth = dataGroupTarget.width;
			layoutTarget.measuredHeight = totalHeight ;
			layoutTarget.measuredMinWidth = dataGroupTarget.width;
			layoutTarget.measuredMinHeight = totalHeight; 
			layoutTarget.setContentSize(dataGroupTarget.width, totalHeight);
		}
		
		private function addToVectorY(index:int, startHeight:Number, elementHeight:Number):void {
			var end:int = startHeight + elementHeight ;
			for (var i:int = startHeight; i < end; i++) {
				yToIndex[i] = index;
			}
		}
		
		private function addToVectorIndex(index:int, y:int):void {
			indexToY[index] = y;
		}
		
		override protected function scrollPositionChanged():void {
			
			var g:GroupBase = target;
			if (!g)
				return;     
			updateScrollRect(g.width, g.height);
			
			var n:int = g.numElements - 1;
			if (n < 0) {
				setIndexInView(-1, -1);
				return;
			}
			
			var scrollR:Rectangle = getScrollRect();
			if (!scrollR) {
				setIndexInView(0, n);
				return;    
			}
			
			var y0:Number = scrollR.top;
			var y1:Number = scrollR.bottom - .0001;
			if (y1 <= y0) {
				setIndexInView(0, n);
				return;
			}

			var i0:int;
			var i1:int;
			if (y0 < 0) {
				i0 = 0;
				i1 = yToIndex.length - 1 > g.height ? yToIndex[g.height + 1]  : g.numElements - 1;
				setIndexInView(i0,i1);
				return;	
			}
			
			if (y1 < yToIndex.length - 1) {
				i0 = yToIndex[Math.floor(y0)];
				i1 = yToIndex[Math.ceil(y1)];
			} else {
				if (yToIndex.length - 1 - g.height < 0)
					i0 = 0;
				else
					i0 = yToIndex[yToIndex.length - 1 - g.height];
				i1 = yToIndex[yToIndex.length - 1];
			}
			setIndexInView(i0,i1);
			if (i0 < _currentFirstIndexInView || i1 > _currentLastIndexInView) {
				g.invalidateDisplayList();
			}
		}
		
		override public function updateDisplayList(containerWidth:Number, containerHeight:Number):void {
			var layoutTarget:GroupBase = target;
			if (!(layoutTarget as DataGroup).dataProvider || (layoutTarget as DataGroup).dataProvider.length == 0)
				return;
			
			var elementHeight:Number;
			var temp:Object = ModelLocator.getInstance().selectedMeal;
			
			//provide the initial values, based on selectedmeal
			if (_firstUpdateDisplayList) {
				_firstUpdateDisplayList = false;
				if (indexToY[indexToY.length - 1] < containerHeight) {
					_firstIndexInView = 0;					
				} else {
					var firstMealEventToShow:Number;
					try {
						firstMealEventToShow = (ModelLocator.getInstance().meals.getItemAt(ModelLocator.getInstance().selectedMeal) as Meal).mealEvent.mealEventId;
						for (var trackingCounter:int = ModelLocator.getInstance().trackingList.length - 1; trackingCounter >= 0;trackingCounter--) {
							if (ModelLocator.getInstance().trackingList.getItemAt(trackingCounter) is MealEvent) {
								if ((ModelLocator.getInstance().trackingList.getItemAt(trackingCounter) as MealEvent).mealEventId == firstMealEventToShow) {
									_firstIndexInView = trackingCounter;
									trackingCounter = -1;
								}
							}
						}
					} catch (erObject:TypeError) {
						//this happens when mealEvent is null, which can be eg when going the tracking a mealtime after having created the latest meal, in this case, we'll simply set the _firstindex to lastelement
						//so the tracking list will show the last element
						_firstIndexInView = ModelLocator.getInstance().trackingList.length - 1;
					}
					if (_firstIndexInView) {//firstindex found, so we can set the scrollrect
						if (indexToY[indexToY.length - 1] - indexToY[_firstIndexInView] < containerHeight) {
							verticalScrollPosition = 	indexToY[indexToY.length - 1] - containerHeight;						
						} else {
							verticalScrollPosition = indexToY[_firstIndexInView];
						}
					}
				}
			}
			
			if (!_firstIndexInView) // if _firstindexinview still not existing then initialize to zero.
				_firstIndexInView = 0;
			
			if (!_lastIndexInView) //this will force to set lastindexinview correctly (and also first)
				scrollPositionChanged();
			
			_currentFirstIndexInView = (_firstIndexInView < 0 ? 0 : _firstIndexInView) ;
			
			var count:int = _currentFirstIndexInView;
			var element:ILayoutElement;
			
			do  {
				element = layoutTarget.getVirtualElementAt(count);
				
				elementHeight = indexToY[count + 1] - indexToY[count];//there's always a count + 1 element because I've added an extra el
				element.setLayoutBoundsSize(layoutTarget.width, elementHeight);
				element.setLayoutBoundsPosition(0, indexToY[count ]);

				
				count++;
			} while (count <= _lastIndexInView);
			_currentLastIndexInView = _lastIndexInView ;
			//now add one additional element before the first, to make scrolling a bit more performant
			if (_currentFirstIndexInView > 0) {
				element = layoutTarget.getVirtualElementAt(_currentFirstIndexInView - 1);
				elementHeight = indexToY[_currentFirstIndexInView] - indexToY[_currentFirstIndexInView - 1];
				element.setLayoutBoundsSize(layoutTarget.width, elementHeight);
				element.setLayoutBoundsPosition(0, indexToY[_currentFirstIndexInView - 1]);
				_currentFirstIndexInView--;
			}
			//add an additional element after the last
			if (_currentLastIndexInView <  (layoutTarget as DataGroup).dataProvider.length - 1) {
				element = layoutTarget.getVirtualElementAt(_currentLastIndexInView + 1);
				elementHeight = indexToY[_currentLastIndexInView + 2] - indexToY[_currentLastIndexInView + 1];
				element.setLayoutBoundsSize(layoutTarget.width, elementHeight);
				element.setLayoutBoundsPosition(0,  indexToY[_currentLastIndexInView +1]);
				_currentLastIndexInView++;
			}
		}
		
		private function setIndexInView(firstIndex:int, lastIndex:int):void {
			if ((_firstIndexInView == firstIndex) && (_lastIndexInView == lastIndex) )
				return;
			_firstIndexInView = firstIndex;
			_lastIndexInView = lastIndex;
			
		}
	}
}