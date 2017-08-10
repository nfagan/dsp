function [mod2d, flow, fhigh] = KL_MI2d_TEM(data,plt)

%%   Compute the two-dimensional Kullback–Leibler MI and plot the result.

%       From Tort et al., J Neurophysiol, 2010

%

%   USAGE:

%       [mod2d, flow, fhigh] = KL_MI2d_TEM(data);

%

%   INPUTS:

%       data   = The unfiltered data, assumes 1000 Hz sampling rate

%       plt    = 'y' or 'n' to plot data

%

%   OUTPUTS:

%       A plot of the two-dimensional modulation index.

%       mod2d  = The two-dim modulation index.

%       flow   = The frequency axis for the lower phase frequencies.

%       fhigh  = The frequency axis for the higher amplitude frequencies.

%

%   DEPENDENCIES:

%    KL_MI_TEM.m

%    eegfilt.m (From EEGLAB Toolbox, https://urldefense.proofpoint.com/v2/url?u=http-3A__www.sccn.ucsd.edu_eeglab_&d=AwIG-g&c=-dg2m7zWuuDZ0MUcV7Sdqw&r=kty6mzZ3RMsEFaTW3w3PXiZhdYSp3Gj7Vnlp9xwP41Q&m=sx_8QhGr00n1fJU11zqW0n_-_uT2J2RB_BbAzYL0b5w&s=4815fYCAcwCHV-qwin2ocwOpvN9Fjo5KwcRAojapneM&e= )

%

%   original function programmed by MAK.  Nov 12, 2007.

%   modified by TEM 9/12/12



if nargin < 2 || isempty(plt);  plt = 'n';  end

Fs = 1e3;

flow1 = (0:0.5:14);   % The phase frequencies (low:stepsize:high)

flow2 = flow1+1;          % width of frequency bands



fhigh1 = (10:4:146);       % The amp frequencies (low:stepsize:high)

fhigh2 = fhigh1+8;        % width of frequency bands



flow = (flow1 + flow2) / 2; fhigh = (fhigh1 + fhigh2) / 2;

mod2d = zeros(length(flow1), length(fhigh1));

% h = waitbar(0,'Filtering data...');



for i=1:length(flow1)

    % Filter the low freq signal & extract its phase.    
    theta=eegfilt(data,Fs,flow1(i),flow2(i), 0, 32); % second term is sampling rate in Hz - replace as needed  
    theta = theta';
    phase = angle(hilbert(theta));
    phase = phase';

%     clc

%     waitbar(i/length(flow1))

    for j=1:length(fhigh1)

        % Filter the high freq signal & extract its amplitude envelope.

        gamma=eegfilt(data,1000,fhigh1(j),fhigh2(j), 0, 32);  % second term is sampling rate in Hz - replace as needed  
        gamma = gamma';
        amp = abs(hilbert(gamma));
        amp = amp';

        [mi] = KL_MI_TEM(amp, phase);   % Compute the modulation index.

        mod2d(i,j) = mi;

    end

end

% close(h)



if plt == 'y'

    %Plot the two-dimensional modulation index.

    figure(gcf); imagesc(flow, fhigh, mod2d');  colorbar; axis xy

    set(gca, 'FontName', 'Arial', 'FontSize', 14); title('KL-MI 2d');

    xlabel('Phase Frequency (Hz)');  ylabel('Envelope Frequency (Hz)');

end

end

