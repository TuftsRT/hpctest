% test_matlab.m
% A basic script to verify MATLAB is functioning

disp('--- MATLAB Test Script ---');

% Check MATLAB version
ver

% Simple computation
A = magic(3);
disp('Magic square of size 3:');
disp(A);

% Verify computation
disp('Sum of each row:');
disp(sum(A, 2));

% Basic plot
x = 0:0.1:2*pi;
y = sin(x);
figure;
plot(x, y, 'LineWidth', 2);
title('Sine Wave');
xlabel('x');
ylabel('sin(x)');
grid on;

disp('Test completed successfully!');
