Event.observe(window, 'load', init);
window.defaultStatus = "Music ain`t Sound without NOIZE";

function init(){
	new IconLinks();
	new initializeView();
	//new BackgroundPulser();
}

var initializeView = Class.create( {
		initialize: function(){
			// flash the banner
			banner = $('banner');
			bannerPuff = $('bannerPuff');
			bannerBasic = $('bannerBasic');
			bannerBasic.pulsate({duration:.3, pulses:3, queue:{position:'end', scope:'main'}});
			bannerBasic.pulsate({delay:.6, duration:.1, pulses:2, queue:{position:'end', scope:'main'}});
			bannerBasic.pulsate({delay:.8, duration:.3, pulses:3, queue:{position:'end', scope:'main'}});
			banner.appear({duration:.1, queue:{position:'end', scope:'main'}});
			// grow the logo-links
			items = $$('.iconLink');
			visible = [];
			while(visible.length < items.length){
				index = Math.round(Math.random()*100) % items.length;
				contained = false;
				for(i=0; i<visible.length; i++){
					if(index==visible[i]){
						contained = true;
					}
				}
				if(!contained){
					items[index].grow({duration:1,queue:{position:'end', scope:'main'}});
					visible = visible.concat(index);
				}
			}
		}
});

/*var BackgroundPulser = Class.create({
		initialize: function(){
			setInterval(function(){
					new Effect.Opacity($('cont0'), {duration: 1.5, from:1, to:.3});
					new Effect.Opacity($('cont0'), {duration: 1.5, delay:1.5, from:.3, to:1});
		}, 3000);
		}
});*/

var IconLinks = Class.create( {
		initialize: function(){
			items = $$('.iconLink');
			for(i=0; i<items.length; i++){
				item = items[i].down('img');
				item.observe('mouseover', this.hover.bind(item));
				item.observe('mouseout', this.mouseOut.bind(item));
				item.setOpacity(.3);
				size = Math.round( (800 / items.length) - 35);
			}
		},
		hover: function(event){
			queue = Effect.Queues.get(this.identify());
			queue.each(function(effect) { effect.cancel(); });
			size = Math.round( (800 / items.length) - 80 );
			new Effect.Parallel([
					new Effect.Morph( this, {sync:true, style:'width:'+size+'px;height:'+size+'px;' } ),
					new Effect.Opacity( this, {sync:true, from: this.getOpacity(), to: 1 } )
			], {queue:{position:'end', scope:this.identify()}}
			);
		},
		mouseOut: function(event){
			queue = Effect.Queues.get(this.identify());
			queue.each(function(effect) { effect.cancel(); });
			size = Math.round( (800 / items.length) - 35 );
			new Effect.Parallel([
					new Effect.Morph( this, {sync:true, style:'width:'+size+'px;height:'+size+'px;' } ),
					new Effect.Opacity( this, {sync:true, from: this.getOpacity(), to: .3 } )
			], {queue:{position:'end', scope:this.identify()}}
			);
		}
});
