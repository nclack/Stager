%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HHMI - Janelia Farms Research Campus 2015 
% Author: Arunesh Mittal
% Email : mittala@janelia.hhmi.org 
%
% Registration code :  Sofroniew, Nick <sofroniewn@janelia.hhmi.org>
%                      https://github.com/sofroniewn/wgnr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Frame
    %% Public/Private Properties
    properties
        frameData;      %Frame data, NxN Matrix
        channel;        %Frame Channel
        zPlane;         %Frame ZPlane
    end
    
    %% Constructor
    methods
        function obj = Frame(varargin)
            if nargin == 1
                obj.frameData = varargin{1};
            end
        end
    end
   
    
    %% Static Methods
    methods (Static)
        %Register frame B to A
        function frame = register(A,B)
            [corr_offset] = gcorr( A, B);
            frame = func_im_shift(B,corr_offset);
        end
        
        %Compute cross correlation
        function [corr_offset corr_2] = gcorr_fast( A, B)
            %GCORR Summary of this function goes here
            % Detailed explanation goes here
            n = size(A,1);
            m = size(A,2);
            B = fliplr(B);
            B = flipud(B);
            corr_2 = ifft2(fft2(A).*fft2(B));
            [max_cc, imax] = max(corr_2(:));
            [rloc, cloc] = ind2sub(size(corr_2),imax);
            md2 = floor(m/2);
            nd2 = floor(n/2);
            if rloc > md2
                row_shift = rloc - m;
            else
                row_shift = rloc;
            end
            if cloc > nd2
                col_shift = cloc - n;
            else
                col_shift = cloc;
            end
            corr_offset = [row_shift col_shift];
        end
        
        %Shift image based on corr offset
        function im_adj = func_im_shift(im,corr_offset)
            im_adj = zeros(size(im),'uint16');
            size_im_x = size(im,1);
            size_im_y = size(im,2);
            corr_offset = -corr_offset;
            if corr_offset(1) > 0 && corr_offset(2) > 0
                im_adj(1+corr_offset(1):size_im_x,1+corr_offset(2):size_im_y) = im(1:size_im_x-corr_offset(1),1:size_im_y-corr_offset(2));
            elseif corr_offset(1) <= 0 && corr_offset(2) > 0
                im_adj(1:size_im_x+corr_offset(1),1+corr_offset(2):size_im_y) = im(1-corr_offset(1):size_im_x,1:size_im_y-corr_offset(2));
            elseif corr_offset(1) <= 0 && corr_offset(2) <= 0
                im_adj(1:size_im_x+corr_offset(1),1:size_im_y+corr_offset(2)) = im(1-corr_offset(1):size_im_x,1-corr_offset(2):size_im_y);
            else
                im_adj(1+corr_offset(1):size_im_x,1:size_im_y+corr_offset(2)) = im(1:size_im_x-corr_offset(1),1-corr_offset(2):size_im_y);
            end
        end
    end
    
    % Public Methods
    methods
        function objClone = clone(obj)
            objClone = stager.stack.Frame();
            objMeta = ?stager.stack.Frame;
            for i=1:length(objMeta.PropertyList)
                propName = objMeta.PropertyList(i).Name;
                objClone.(propName) = obj.(propName);   
            end
        end
    end
end
