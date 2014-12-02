
function mobiusnet()
	% mobiusnet - Renders a Mobius Net
	% TODO: doc

	%% setup GUI
	gui = {};
	gui.screenSz = get(0, 'ScreenSize');
	gui.screenSz = gui.screenSz(3:4);
	gui.fig = figure('Position', [gui.screenSz/10 gui.screenSz*8/10]);
	gui.settings = uipanel(gui.fig, 'Position', [0 0 .2 1],...
			'Title', 'Input settings', 'BackgroundColor', 'none'); % bgcolor Screws title

	gui.tbl = uitable(gui.settings, 'Units', 'normalized',...
			'Position', [0 .7 1 .3], 'Data', zeros(5, 2),...
			'ColumnName', {'X', 'Y'},...
			'RowName', {'O', 'A' 'B', 'Sa', 'Sb'},...
	'ColumnWidth', {100, 200});    
	gui.pick = uicontrol(gui.settings, 'Style', 'pushbutton',...
			'Units', 'normalized', 'Position', [.1 .65 .8 .04],...
			'String', 'Pick coordinates');
	gui.render = uicontrol(gui.settings, 'Style', 'pushbutton',...
			'Units', 'normalized', 'Position', [.1 .60 .8 .04],...
			'String', 'Render Möbius Net');
	gui.save = uicontrol(gui.settings, 'Style', 'pushbutton',...
			'Units', 'normalized', 'Position', [.1 .55 .8 .04],...
			'String', 'Save image');
	gui.save = uicontrol(gui.settings, 'Style', 'pushbutton',...
		'Units', 'normalized', 'Position', [.1 .50 .8 .04],...
		'String', 'Reset');
		
	% TODO: reset btn

	axes('Position', [0.2 0 0.8 1]);
	gui.axes = gca();
	hold(gui.axes);
	axis(gui.axes, 'off', 'manual');
	gui.axesSz = getpixelposition(gui.axes);
	gui.axesSz = gui.axesSz(3:4);

	%% Callbacks  % TODO: move into code above
	set(gui.pick, 'Callback', @pickCoords);
	set(gui.settings, 'ResizeFcn', @settingsResize);

	%% Reset & wait for input
		resetAll();
		
	%% Callback functions
	function pickCoords(hO, evt)
		resetAll();
		O = getPoint('O', gui);
		A = getPoint('A', gui);
		plotLine(O, A);
		B = getPoint('B', gui);
		plotLine(O, B);
		plotLine(A, B);

		Sa = getPoint('Sa', gui, O, A);
		plotLine(Sa, B);
		Sb = getPoint('Sb', gui, O, B);
		plotLine(Sb, A);

		data = [O; A; B; Sa; Sb];
		set(gui.tbl, 'Data', data);
	end

	function settingsResize(hO, evt)
		width = getpixelposition(gui.settings);
		width = width(3)/2 - 20;
		set(gui.tbl, 'ColumnWidth', {width, width});
	end

	%% Resets all states to initial
	function resetAll()
			defaultData = [
					0 0
					0 1;
					1 0;
					0 0.1;
					0.1 0
				];
			cla(gui.axes);
			fill([0 1 1 0], [0 0 1 1], 'white');
			set(gui.tbl, 'Data', defaultData);
	end

end


%% Utilities
function ret = projectOnLine(p, A, B)
	AB = (B-A);
	dist = dot(AB,AB);
	if(dist == 0)
		ret = A;
	else
		Ap = (p-A);
		t = dot(Ap,AB)/dist;
		if (t < 0.0)
			ret = A;
		elseif (t > 1.0)
			ret = B;
		else
			ret = A + t * AB;
		end
	end
end

function point = getPoint(label, gui, lA, lB)
	point = ginput(1);

	if nargin == 4
		point = projectOnLine(point, lA, lB);
		% FIXME: if point is outside line, set default?
	end
	
	w = gui.axesSz(1);
	h = gui.axesSz(2);
	
	offx = 4 / w;
	offy = 4 / h;

	x = point(1);
	y = point(2);
	markx = ([-offx +offx +offx -offx] + x);
	marky = ([-offy -offy +offy +offy] + y);

	fill(markx, marky, 'blue');
	text(x + 2*offx, y, label);
end

function plotLine(A, B)
	AB = [A;B];
	line(AB(:,1), AB(:,2));
end

