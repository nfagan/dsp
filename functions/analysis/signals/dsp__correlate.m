function A = dsp__correlate(A, B)

[r, p] = corr( A.data, B.data );
A = A.collapse_non_uniform();
A = A(1);
A.data = { struct('r', r, 'p', p) };

end