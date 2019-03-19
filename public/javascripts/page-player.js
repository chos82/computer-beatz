/*Event.observe(window, 'load', init);

	function init(){
		window.pp = new PagePlayer(soundManager);
	}*/
	
	soundManager.allowPolling = true;     // enable flash status updates. Required for whileloading/whileplaying.
	soundManager.consoleOnly = false;     // if console is being used, do not create/write to #soundmanager-debug
	soundManager.debugMode = false;        // enable debugging output (div#soundmanager-debug, OR console..)
	soundManager.debugFlash = false;      // enable debugging output inside SWF, troubleshoot Flash/browser issues
	soundManager.flashLoadTimeout = 1000; // ms to wait for flash movie to load before failing (0 = infinity)
	soundManager.flashVersion = 9;        // version of flash to require, either 8 or 9. Some features require 9.
	soundManager.nullURL = 'about:blank'; // (Flash 8 only): URL of silent/blank MP3 for unloading/stop request.
	soundManager.url = '/soundmanager/swf';  // path (directory) where SM2 .SWF files will be found.
	soundManager.useConsole = false;       // use firebug/safari console.log()-type debug console if available
	soundManager.useMovieStar = false;     // enable Flash 9.0r115+ MPEG4 audio + experimental video support
	soundManager.useFastPolling = false;  // fast timer=higher callback frequency, combine w/useHighPerformance
	soundManager.useHighPerformance = true;// position:fixed flash movie for faster JS/flash callbacks
	soundManager.waitForWindowLoad = true; // always delay soundManager.onload() until after window.onload()
	soundManager.wmode = 'transparent';     // null, transparent, opaque (last two allow HTML on top of flash)
	soundManager.allowFullScreen = false;    // enter full-screen (via double-click on movie) for flash 9+ video
	soundManager.allowScriptAccess = 'always'; // for scripting SWF (object/embed prop.), 'always' or 'sameDomain'
	soundManager.useFlashBlock = true;      // better handling of SWF if load fails, let user unblock. See demo.
	soundManager.useHTML5Audio = false;     // beta feature: Use HTML5 Audio() where supported.
	soundManager.defaultOptions = {
		usePeakData: true,
		useWaveformData: true,
		useEQData: true
	}

	var PagePlayer = Class.create( {
		initialize: function(sm){
			this.sm = sm;
			this.stop = $('p_stop');
			this.playPause = $('p_play-pause');
			this.skpBwd = $('p_skp-bwd');
			this.skpFwd = $('p_skp-fwd');
			this.level = $('p_level');
			this.levelHandle = $('p_levelHandle');
			this.loadBar = $('loadBar');
			this.posBar = $('posBar');
			this.status = $('status');
			this.volumeBar = $('volumeBar');
			this.time = $('time');
			this.pos = $('pos');
			this.dur = $('dur');
			this.show = $('show');
			this.download = $('download');
			this.visualizations = $('visualizations');
			this.animation = $('animation');
			this.animSelect = this.animation.adjacent('.bt');
			for(i = 0; i<this.animSelect.length; i++){
				this.animSelect[i].observe('mouseover', this.animSelect_over.bind(this));
				this.animSelect[i].observe('mouseout', this.animSelect_out.bind(this));
				this.animSelect[i].observe('click', this.animSelect_click.bind(this));
			}
			this.scrollUp = $('scrollUp');
			this.scrollDown = $('scrollDown');
			this.dataWidth = $('status').getWidth();
			this.barWidth = this.dataWidth - 18;// - $('status').getStyle('padding-left') - $('status').getStyle('padding-right');
			this.volume = 75;
			this.tracks = $$('.audio'); //get all sounds
			for(i=0; i<this.tracks.length; i++){
				this.tracks[i].observe('click', this.track_click.bind(this));
			}
			if (this.tracks.length > 3) {
				this.scrollDown.show();
				this.MSI = 1;
			}
			if (this.tracks.length < 3) {
				var shrink = $('playlist').down().getHeight()*(3-this.tracks.length) *-1;
				window.resizeBy(0, shrink);
			}
			this.index = 0;
			this.muted = false;
			this.stop.observe( 'mouseover', this.stop_over.bind(this) );
			this.stop.observe( 'mouseout', this.stop_out.bind(this) );
			this.stop.observe( 'click', this.stop_click.bind(this) );
			this.playPause.observe( 'mouseover', this.playPause_over.bind(this) );
			this.playPause.observe( 'mouseout', this.playPause_out.bind(this) );
			this.playPause.observe( 'click', this.playPause_click.bind(this) );
			this.skpBwd.observe( 'mouseout', this.skpBwd_out.bind(this) );
			this.skpBwd.observe( 'mouseover', this.skpBwd_over.bind(this) );
			this.skpBwd.observe( 'click', this.skpBwd_click.bind(this) );
			this.skpFwd.observe( 'mouseover', this.skpFwd_over.bind(this) );
			this.skpFwd.observe( 'mouseout', this.skpFwd_out.bind(this) );
			this.skpFwd.observe( 'click', this.skpFwd_click.bind(this) );
			this.level.observe( 'mouseover', this.level_over.bind(this) );
			this.level.observe( 'mouseout', this.level_out.bind(this) );
			this.level.observe( 'click', this.level_click.bind(this) );
			this.levelHandle.observe( 'mouseover', this.levelHandle_over.bind(this) );
			this.levelHandle.observe( 'mouseout', this.levelHandle_out.bind(this) );
			this.status.observe( 'click', this.setPos.bind(this) );
			this.visualizations.observe( 'mouseover', this.visual_over.bind(this) );
			this.visualizations.observe( 'mouseout', this.visual_out.bind(this) );
			this.visualizations.observe( 'click', this.visual_click.bind(this) );
			this.scrollUp.observe( 'mouseover', this.scrollUp_over.bind(this) );
			this.scrollUp.observe( 'mouseout', this.scrollUp_out.bind(this) );
			this.scrollUp.observe( 'click', this.scrollUp_click.bind(this) );
			this.scrollDown.observe( 'mouseover', this.scrollDown_over.bind(this) );
			this.scrollDown.observe( 'mouseout', this.scrollDown_out.bind(this) );
			this.scrollDown.observe( 'click', this.scrollDown_click.bind(this) );
			w = Math.round(this.volume*1,05);
			this.volumeBar.setStyle({
				width: w + 'px'
			});
			this.slider = new Control.Slider('p_levelHandle', 'p_levelTrack', {
				range: $R(0,100),
				sliderValue: 75,
				onChange: function(value) { 
        			pp.volume = value;
 				},
				onSlide: function(value){
					w = Math.round(value*1,05);
					pp.volumeBar.setStyle({
						width: w + 'px'
					});
					if(pp.playingTrack)
						pp.playingTrack.setVolume(value);
				}
			});
		},
		track_click: function(event){
			element = Event.element(event);
			event.stop();
			if (this.playingTrack)
				this.playingTrack.destruct();
			this.tracks[this.index].removeClassName('playing');
			this.index = element.identify().substr(2);
			this.playTrack();
		},
		stop_over: function(event){
			this.stop.setStyle({
				background: 'url(/images/player/01-stop_hover.png)'
			});
		},
		stop_out: function(event){
			this.stop.setStyle({
				background: 'url(/images/player/01-stop.png)'
			});
		},
		stop_click: function(event){
			if (this.playingTrack)
				this.playingTrack.destruct();
			this.playing = false;
			this.stopped = true;
			this.tracks[this.index].removeClassName('playing');
			this.index = 0;
			this.loadBar.setStyle({
				width: '0'
			});
			this.posBar.setStyle({
				width: '0'
			});
			this.playPause.setStyle({
				background: 'url(/images/player/02-pause-play.png) left no-repeat'
			});
			this.time.setStyle({
				textDecoration: 'none'
			});
			this.pos.update('00:00');
			this.dur.update('00:00');
			for(i=0; i<this.tracks.length; i++){
				if(i<3)
					this.tracks[i].show();
				else
					this.tracks[i].hide();
			}
			if(this.tracks.length > 3)
				this.scrollDown.show();
			this.scrollUp.hide();
			this.MSI = 1;
		},
		playPause_over: function(event){
			if (this.playing) {
				this.playPause.setStyle({
					background: 'url(/images/player/02-pause_hover.png) left no-repeat'
				});
			} else {
				this.playPause.setStyle({
					background: 'url(/images/player/02-play_hover.png) left no-repeat'
				});
			}
		},
		playPause_out: function(event){
			if (this.playing) {
				this.playPause.setStyle({
					background: 'url(/images/player/02-playing.png) left no-repeat'
				});
			} else if(this.stopped){
				this.playPause.setStyle({
					background: 'url(/images/player/02-pause-play.png) left no-repeat'
				});
			} else{
				this.playPause.setStyle({
					background: 'url(/images/player/02-pause_hover.png) left no-repeat'
				});
			}
		},
		playPause_click: function(event){
			if (this.playing) {
				this.playPause.setStyle({
					background: 'url(/images/player/02-pause-play.png) left no-repeat'
				});
				this.playing = false;
				this.playingTrack.pause();
				this.time.setStyle({
					textDecoration: 'blink'
				});
			}
			else {
				this.playPause.setStyle({
					background: 'url(/images/player/02-playing.png) left no-repeat'
				});
				this.playing = true;
				if(this.stopped){
					this.playTrack();
				} else
					this.playingTrack.resume();
				this.time.setStyle({
					textDecoration: 'none'
				});
			}
		},
		skpBwd_over: function(event){
			if (this.index > 0 || this.playing) {
				this.skpBwd.setStyle({
					background: 'url(/images/player/03-skipBwd_hover.png)'
				});
			}
		},
		skpBwd_out: function(event){
			this.skpBwd.setStyle({
				background: 'url(/images/player/03-skipBwd.png)'
			});
		},
		skpBwd_click: function(event){
			if (this.index > 0) {
				this.playingTrack.destruct();
				this.tracks[this.index].removeClassName('playing');
				this.index--;
				this.playTrack();
				if(this.index < this.MSI -1)
					this.scrollUp_click(null);
			} else if(this.playing){
				this.playingTrack.setPosition(0);
			}
		},
		skpFwd_over: function(event){
			if (this.index < this.tracks.length -1) {
				this.skpFwd.setStyle({
					background: 'url(/images/player/04-skipFwd_hover.png)'
				});
			}
		},
		skpFwd_out: function(event){
			this.skpFwd.setStyle({
				background: 'url(/images/player/04-skipFwd.png)'
			});
		},
		skpFwd_click: function(event){
			if (this.index < this.tracks.length -1) {
				this.playingTrack.destruct();
				this.tracks[this.index].removeClassName('playing');
				this.index++;
				this.playTrack();
				if(this.index > this.MSI +1)
					this.scrollDown_click(null);
			}
		},
		level_over: function(event){
			if (this.muted) {
				this.level.setStyle({
					background: 'url(/images/player/05-level-muted_hover.png)',
				});
			} else{
				this.level.setStyle({
					background: 'url(/images/player/05-level_hover.png)',
				});
			}
		},
		level_out: function(event){
			if (this.muted) {
				this.level.setStyle({
					background: 'url(/images/player/05-level-muted.png)',
				});
			} else{
				this.level.setStyle({
					background: 'url(/images/player/05-level.png)',
				});
			}
		},
		level_click: function(event){
			this.playingTrack.toggleMute();
			if (this.muted) {
				this.level.setStyle({
					background: 'url(/images/player/05-level.png)',
				});
				this.muted = false;
			}
			else{
				this.level.setStyle({
					background: 'url(/images/player/05-level-muted.png)',
				});
				this.muted = true;
			}
		},
		levelHandle_over: function(event){
			this.levelHandle.setStyle({
				backgroundColor: '#FF4900',
			});
		},
		levelHandle_out: function(event){
			this.levelHandle.setStyle({
				backgroundColor: '#bbb',
			});
		},
		visual_over: function(){
			this.visualizations.setStyle({
				borderColor: '#888'
			});
		},
		visual_out: function(){
			this.visualizations.setStyle({
				borderColor: 'black'
			});
		},
		visual_click: function(){
			this.visualizations.blindUp();
			this.animation.blindDown();
			this.visualize = 'peak';
			$('d_peak').show();
			$('peak').addClassName('current');
			window.resizeBy(0, 60);
		},
		animSelect_over: function(event){
			element = Event.element(event);
			element.setStyle({
				backgroundColor: '#8080ff'
			});
		},
		animSelect_out: function(event){
			element = Event.element(event);
			if (element.hasClassName('current')) {
				element.setStyle({
					backgroundColor: '#bfbfff'
				});
			}
			else {
				element.setStyle({
					backgroundColor: '#888'
				});
			}
		},
		animSelect_click: function(event){
			element = Event.element(event);
			for (i = 0; i < this.animSelect.length; i++) {
				if (this.animSelect[i].hasClassName('current')) {
					if(this.animSelect[i] == element)
				 		return;
					this.animSelect[i].removeClassName('current');
					this.animSelect[i].setStyle({
						backgroundColor: '#888'
					});
				}
			}
			if(element.identify() != 'off')
				element.addClassName('current');
			switch (element.identify()) {
				case 'peak':
					this.visualize = 'peak';
					$('d_spectrum').update('').hide();
					$('d_wave').update('').hide();
					$('d_peak').show();
					this.animDivs = null;
					break;
				case 'spectrum':
					this.visualize = 'spectrum';
					$('d_peak').hide();
					$('d_wave').update('').hide();
					spec = $('d_spectrum');
					spec.show();
					for(i=0; i<256; i++){
						spec.insert('<div id="'+'spec'+i+'"></div>');
					}
					this.animDivs = spec.childElements();
					break;
				case 'wave':
					this.visualize = 'wave';
					$('d_peak').hide();
					$('d_spectrum').update('').hide();
					wave = $('d_wave');
					wave.show();
					for(i=0; i<256; i++){
						wave.insert('<div id="'+'wave'+i+'"></div>');
					}
					this.animDivs = wave.childElements();
					break;
				case 'off':
					this.visualize = null;
					this.visualizations.blindDown();
					this.animation.blindUp();
					$('d_spectrum').update('').hide();
					$('d_wave').update('').hide();
					window.resizeBy(0, -60);
					this.animDivs = null;
					break;
			}
		},
		scrollUp_over: function(event){
			this.scrollUp.setStyle({
				backgroundColor: '#FF4900',
				backgroundImage: 'url(/images/player/scrollUp_hover.png)'
			})
		},
		scrollUp_out: function(event){
			this.scrollUp.setStyle({
				backgroundColor: '#888',
				backgroundImage: 'url(/images/player/scrollUp.png)'
			})
		},
		scrollUp_click: function(event){
			this.tracks[this.MSI +1].blindUp();
			this.tracks[this.MSI -2].blindDown();
			this.MSI--;
			if(this.MSI -1 <= 0)
				this.scrollUp.puff();
			if(!(this.tracks[this.tracks.length -1].visible() && this.scrollDown.visible()))
				this.scrollDown.appear();
		},
		scrollDown_over: function(event){
			this.scrollDown.setStyle({
				backgroundColor: '#FF4900',
				backgroundImage: 'url(/images/player/scrollDown_hover.png)'
			})
		},
		scrollDown_out: function(event){
			this.scrollDown.setStyle({
				backgroundColor: '#888',
				backgroundImage: 'url(/images/player/scrollDown.png)'
			})
		},
		scrollDown_click: function(event){
			this.tracks[this.MSI -1].blindUp();
			this.tracks[this.MSI +2].blindDown();
			this.MSI++;
			if(this.MSI +1 >= this.tracks.length -1)
				this.scrollDown.puff();
			if(!(this.tracks[0].visible() && this.scrollUp.visible()))
				this.scrollUp.appear();
		},
		setPos: function(event){
			if(this.playingTrack){
				var pos = (event.pointerX() - 38) / this.barWidth * this.playingTrack.duration;
				this.playingTrack.setPosition(pos);
			}
		},
		playTrack: function(){
			this.playingTrack = this.sm.createSound({
 				id: 'tr' + this.index,
 				url: pp.tracks[this.index].readAttribute('href'),
				volume: pp.volume,
				autoPlay: true,
				whileloading: pp.soundIsLoading,
				whileplaying: pp.soundIsPlaying,
				onload: pp.soundLoaded,
				onfinish: pp.playNext
			});
			this.tracks[this.index].addClassName('playing');
			this.stopped = false;
			this.playing = true;
			this.playPause.setStyle({
				background: 'url(/images/player/02-playing.png) left no-repeat'
			});
			this.time.setStyle({
				textDecoration: 'none'
			});
			this.download.writeAttribute({href: this.tracks[this.index].readAttribute('href')});
			dbi = this.tracks[this.index].next().innerHTML;
			this.show.writeAttribute({href: 'http://' + location.hostname + ':3000/releases/' + dbi})
		},
		soundIsLoading: function(){
			var w = pp.barWidth * this.bytesLoaded / this.bytesTotal;
			pp.loadBar.setStyle({
				width: w + 'px'
			})
		},
		soundLoaded: function(){
			pp.dur.update(pp.ms2display(this.duration));
		},
		soundIsPlaying: function(){
			var w = pp.barWidth * this.position / this.duration;
			pp.posBar.setStyle({
				width: w + 'px'
			});
			pp.pos.update(pp.ms2display(this.position));
			switch(pp.visualize){
				case 'peak':
					left = Math.round(pp.dataWidth * this.peakData.left);
					right = Math.round(pp.dataWidth * this.peakData.right);
					$('left').setStyle({
						width: left + 'px'
					});
					$('right').setStyle({
						width: right + 'px'
					});
					break;
				case 'spectrum':
					for(i=255; i>=0; i--){
						h = 50 - this.eqData[i]*50;
						h = Math.round(h);
						pp.animDivs[i].setStyle({
							height: h + 'px'
						});
					}
					break;
				case 'wave':
					for(i=0; i<256; i++){
						pos = 25 + this.waveformData.left[i]*24;
						pos = Math.round(pos);
						pp.animDivs[i].setStyle({
							top: pos + 'px'
						});
					}
					break;
			}
		},
		playNext: function(){
			pp.playingTrack.destruct();
			pp.tracks[pp.index].removeClassName('playing');
			if (pp.index < pp.tracks.length -1) {
				pp.index++;
				pp.playTrack();
				if(pp.index > pp.MSI +1)
					pp.scrollDown_click(null);
			} else{
				pp.stop_click();
			}
		},
		ms2display: function(v){
			s = Math.round(v / 1000);
			m = Math.floor(s / 60);
			r = s - m * 60;
			lzm = m < 10 ? '0' : '';
			lzs = r < 10 ? '0' : '';
			return lzm + m + ':' + lzs + r;
		}
	} );
	
	// soundmanager
	soundManager.onload = function() {
		window.pp = new PagePlayer(soundManager);
		pp.playTrack();
	}
	
	soundManager.onerror = function() {
		// SM2 could not start, no sound support, something broke etc. Handle gracefully.
  		alert('Player could not be initialized. Sorry.')
	}

