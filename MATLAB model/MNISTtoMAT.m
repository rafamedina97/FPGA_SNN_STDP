clear all

[x y] = readMNIST("../MNIST/train-images", "../MNIST/train-labels", 60000, 0);
[x_test y_test] = readMNIST("../MNIST/t10k-images", "../MNIST/t10k-labels", 10000, 0);
[x_aux y_aux] = readMNIST("../MNIST/train-images", "../MNIST/train-labels", 50, 0);

x_fi = fi(x_aux,0,8,8);
y_fi = fi(y_aux,0,8,8);
x_test_fi = fi(x_test,0,8,8);
y_test_fi = fi(y_test,0,8,8);

fileID_x = fopen('x_train.txt', 'w');
fileID_y = fopen('y_train.txt', 'w');
for k = 1:length(y_aux)
    k_fi = fi(k,0,8,0);
    fprintf(fileID_x, '%s\n', hex(k_fi));
    fprintf(fileID_y, '%s\n', hex(y_fi(k)));
    for j = 1:32
        for i = 1:32
            fprintf(fileID_x, '%s\n', hex(x_fi(i,j,k)));
        end
    end
end
fclose(fileID_x);
fclose(fileID_y);

for k = 1:length(y_aux)
    filename = strcat('images/x_', int2str(k), '.txt');
    fileID_x = fopen(filename, 'w');
    fprintf(fileID_x, '%c', 0);
    fprintf(fileID_x, '%c', 0);
    fprintf(fileID_x, '%c', 0);
    k_fi = fi(k,0,8,0);
    fprintf(fileID_x, '%c', int(k_fi));
    for j = 3:30
        for i = 3:30
            fprintf(fileID_x, '%c', int(x_fi(i,j,k)));
        end
    end
    fclose(fileID_x);
end

% fileID_x = fopen('x_test.txt', 'w');
% fileID_y = fopen('y_test.txt', 'w');
% for k = 1:length(y_test)
%     k_fi = fi(k,0,8,0);
%     fprintf(fileID_x, '%s\n', hex(k_fi));
%     fprintf(fileID_y, '%s\n', hex(y_test_fi(k)));
%     for j = 1:32
%         for i = 1:32
%             fprintf(fileID_x, '%s\n', hex(x_test_fi(i,j,k)));
%         end
%     end
% end
% fclose(fileID_x);
% fclose(fileID_y);

save('mnist.mat', 'x', 'y', 'x_test', 'y_test', 'x_aux', 'y_aux')