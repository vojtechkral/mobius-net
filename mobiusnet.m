function mobiusnet()
	% mobiusnet - Renders a Mobius Net
	%
	% Renders a Mobius Net (a checkerboard in perspective) in a figure.
	% See http://mathworld.wolfram.com/MoebiusNet.html
	% for more information on Mobius Nets.
	% 
	% An enclosing triangle as well as two starting points may be configured
	% using mouse. Numerical coordinates of these points are displayed in
	% a table on the left side of the figure.
	% The resulting picture can be saved into a png file.
	%

	%% setup GUI
	gui = {};
	gui.screenSz = get(0, 'ScreenSize');
	gui.screenSz = gui.screenSz(3:4);
	gui.fig = figure('Position', [gui.screenSz/10 gui.screenSz*8/10],...
		'MenuBar', 'none');
	
	gui.pstatus = uipanel(gui.fig, 'Position', [0 .9 .2 .1],...
		'Title', 'Status', 'BackgroundColor', 'none');
	gui.status = uicontrol(gui.pstatus, 'Style', 'text',...
		'Units', 'normalized', 'Position', [.1 .1 .8 .8]);
	
	gui.settings = uipanel(gui.fig, 'Position', [0 0 .2 .9],...
		'Title', 'Input settings', 'BackgroundColor', 'none',...
		'ResizeFcn', @settingsResize); 

	gui.tbl = uitable(gui.settings, 'Units', 'normalized',...
		'Position', [0 .7 1 .3], 'Data', zeros(5, 2),...
		'ColumnName', {'X', 'Y'},...
		'RowName', {'O', 'X' 'Y', 'x1', 'y1'},...
		'ColumnWidth', {100, 200});    
	gui.pick = uicontrol(gui.settings, 'Style', 'pushbutton',...
		'Units', 'normalized', 'Position', [.1 .65 .8 .04],...
		'String', 'Pick coordinates', 'Callback', @pickCoords);
	gui.render = uicontrol(gui.settings, 'Style', 'pushbutton',...
		'Units', 'normalized', 'Position', [.1 .60 .8 .04],...
		'String', 'Render Mobius Net', 'Callback', @render);
	gui.save = uicontrol(gui.settings, 'Style', 'pushbutton',...
		'Units', 'normalized', 'Position', [.1 .55 .8 .04],...
		'String', 'Save image', 'Callback', @save);
	gui.save = uicontrol(gui.settings, 'Style', 'pushbutton',...
		'Units', 'normalized', 'Position', [.1 .50 .8 .04],...
		'String', 'Reset', 'Callback', @resetAll);

	axes('Position', [0.2 0 0.8 1]);
	gui.axes = gca();
	hold(gui.axes);
	axis(gui.axes, 'off', 'manual');
	gui.axesSz = getpixelposition(gui.axes);
	gui.axesSz = gui.axesSz(3:4);
	
	textctrls = findall([gui.settings gui.pstatus],...
		'Type', 'uicontrol', 'Style', 'text');
	set(textctrls, 'BackgroundColor', get(gui.fig, 'Color'));
	
	%% Reset & wait for input
	resetAll();

	
	%% Event callback functions & GUI utils
	function setStatus(status)
		if nargin > 0
			set(gui.status, 'String', status);
		else
			set(gui.status, 'String', 'Ready...');
		end
	end
	
	function pickCoords(hO, evt)
		resetAll();
		setStatus('Picking point O...');
		O = getPoint('O', gui);
		setStatus('Picking point X...');
		X = getPoint('X', gui);
		plotLine(O, X);
		setStatus('Picking point Y...');
		Y = getPoint('Y', gui);
		plotLine(O, Y);
		plotLine(X, Y);

		setStatus('Picking point x1...');
		x1 = getPoint('x1', gui, O, X);
		plotLine(x1, Y);
		setStatus('Picking point y1...');
		y1 = getPoint('y1', gui, O, Y);
		plotLine(y1, X);

		data = [O; X; Y; x1; y1];
		set(gui.tbl, 'Data', data);
		setStatus();
	end

	function settingsResize(hO, evt)
		width = getpixelposition(gui.settings);
		width = width(3)/2 - 20;
		set(gui.tbl, 'ColumnWidth', {width, width});
	end

	function render(h0, evt)
		% Set status & disable uicontrols while rendering:
		setStatus('Rendering, please wait...');
		controls = findall(gui.settings, 'Type', 'uicontrol', 'Style', 'pushbutton');
		set(controls, 'Enable', 'Off');
		drawnow();
		
		renderMobiusNet(gui);
		
		% Reenable uicontrols:
		set(controls, 'Enable', 'On');
		setStatus();
	end

	function save(h0, evt)
		fn = uiputfile('*.png', 'Save current image');
		if fn
			f = getframe(gui.axes);
			img = frame2im(f);
			imwrite(img, fn);
		end
	end

	function resetAll(hO, evt)
		% FIXME: cancel ginput if any
		defaultData = [
				0 0
				1 0;
				0 1;
				0.1 0;
				0 0.1
			];
		cla(gui.axes);
		fill([0 1 1 0], [0 0 1 1], 'white');
		set(gui.tbl, 'Data', defaultData);
		setStatus();
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

		% Check if the point is too close to lA or lB:
		threshold = 0.05;
		if norm(lA - point) < threshold
			line = lB - lA;
			lnorm = norm(line);
			point = lA + line/lnorm * lnorm * threshold;
		elseif norm(lB - point)< threshold
			line = lB - lA;
			lnorm = norm(line);
			point = lB + line/lnorm * lnorm * threshold;
		end
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

function fillQuad(points, color)
	% shorthand for easier quadrilateral polygon fill
	fill(points(:,1), points(:,2), color);
end

function point = lineIntersect(a1, a2, b1, b2)
	l1 = cross([a1 1], [a2 1]);
	l2 = cross([b1 1], [b2 1]);
	point = cross(l1, l2);
	point = point(1:2) / point(3);
end

%% Mobius net algorithm
% Rendering is done in "waves" - each wave is a set of
% quadrilaterals with the same distance from the origin point (O).
% Rendering stops once the distance between waves becomes insignificant.
% Each wave reuses data from the previous one via a context variable.
function renderMobiusNet(gui)
		% Clear axes:
		cla(gui.axes);
		fill([0 1 1 0], [0 0 1 1], 'white');

		% Setup rendering context:
		ctx = {};
		data = get(gui.tbl, 'Data');
		ctx.O = data(1,:);
		ctx.X = data(2,:);
		ctx.Y = data(3,:);
		ctx.x1 = data(4,:);
		ctx.y1 = data(5,:);
		
		% Compute first internal (p11) and horizon (H) points:
		p11 = lineIntersect(ctx.x1, ctx.Y, ctx.y1, ctx.X);
		ctx.H = lineIntersect(ctx.O, p11, ctx.X, ctx.Y);  
		
		% Buffer for internals points:
		ctx.ps = [ctx.y1; p11; ctx.x1];
		
		% Buffers for x and y points:
		ctx.xs = [ctx.x1];
		ctx.ys = [ctx.y1];
		
		% Checkerboard colors:
		ctx.colors = [[0 0 0]; [1 1 1]];
		ctx.run = 0;  % indicates current run: odd or even
		
		% Draw the first quadrilateral:
		fillQuad([ctx.O; ctx.x1; p11; ctx.y1], ctx.colors(1,:));
		
		% Draw checkerboard waves until distance between them
		% becomes insignificant
		threshold = 1e-3;
		ctx.dist = Inf;     % distance between last and new wave
		while ctx.dist > threshold
			ctx = mobiusWave(ctx);
		end
end

function ctx = mobiusWave(ctx)
	% Compute intermediate points:
	px = lineIntersect(ctx.xs(end,:), ctx.H, ctx.y1, ctx.X);
	py = lineIntersect(ctx.ys(end,:), ctx.H, ctx.x1, ctx.Y);

	% Compute this wave's x & y:
	xn = lineIntersect(px, ctx.Y, ctx.O, ctx.X);
	yn = lineIntersect(py, ctx.X, ctx.O, ctx.Y);
	
	% Generate list of this wave's points:
	mid = ceil(size(ctx.ps, 1) / 2); % Idx of the middle point in previsou ps
	ps = [yn; py];
	for ix = 2:mid
		isec = lineIntersect(ctx.ps(ix,:), ctx.H, yn, ctx.X);
		ps = [ps; isec];
	end
	for iy = mid+1:size(ctx.ps, 1)-1
		isec = lineIntersect(ctx.ps(iy,:), ctx.H, xn, ctx.Y);
		ps = [ps; isec];
	end
	ps = [ps; px; xn];

	% Draw quadrilaterals:
	%  triplicate the middle points in previous ps
	%  for easier polygon drawing:
	pprev = [ ctx.ps(1:mid,:); ctx.ps(mid,:); ctx.ps(mid:end,:) ];
	mid = mid + 1;
	%  generate a color pattern for this wave:
	pattern = mod([1:mid-1 mid-1:-1:1] + ctx.run, 2) + 1; 
	for ip = 1:size(ps, 1)-1
		fillQuad([pprev([ip ip+1],:); ps([ip+1 ip],:)], ...
		         ctx.colors(pattern(ip),:));
	end

	% Compute this wave's distance:
	xdist = norm(xn - ctx.xs(end,:));
	ydist = norm(yn - ctx.ys(end,:));
	ctx.dist = max([xdist ydist]);
	
	% Update context data for next round:
	ctx.ps = ps;
	ctx.xs = [ctx.xs; xn];
	ctx.ys = [ctx.ys; yn];
	ctx.run = ~ctx.run;
end
