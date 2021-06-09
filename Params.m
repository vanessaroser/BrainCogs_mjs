classdef Params
    properties
        
    end
    methods
        function obj = Params('figs')
            cbrew = brewColorSwatches();
            obj.colors = struct(...
                'pCorrect', cbrew.blue, 'pOmit', cbrew.orange, 'mean_velocity',...
                cbrew.green, 'nCompleted', cbrew.black,...
                'left',cbrew.red,'right',cbrew.blue);
        end
    end
    
    %    methods
    %       function r = roundOff(obj)
    %          r = round([obj.Value],2);
    %       end
    %       function r = multiplyBy(obj,n)
    %          r = [obj.Value] * n;
    %       end
    %    end
end