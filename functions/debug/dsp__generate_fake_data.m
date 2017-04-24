function signals = dsp__generate_fake_data(signals)

tests.window = 21;  %   t = 0;
tests.f = 1e2;
tests.fs = 1e3;
tests.time = 1:length(signals.data{1});
tests.sine = 3 .* sin(2 * pi * tests.f/tests.fs * tests.time);
tests.noise_amplitude = 1.5;
tests.modified_data = signals.data(:,tests.window);

for i = 1:numel(tests.modified_data)
    tests.modified_data{i} = tests.sine + rand(1, length(tests.sine)) * tests.noise_amplitude;
end

tests.data = signals.data;
tests.data(:,tests.window) = tests.modified_data;

signals.data = tests.data;

end

