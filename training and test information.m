% The test dataset information can be referred to the 6127-th~7138-th (1012 files) audio files of "tr05_simu.json", where the noise files were used as
% BGD_150204_010_BUS.CH1.wav,
% BGD_150203_010_STR.CH1.wav,
% BGD_150203_010_PED.CH1.wav,
% BGD_150203_010_CAF.CH1.wav,


% The training dataset information can be referred to the 1-st~4313-th (4313 files) audio files of "tr05_simu.json", where the noise files were used as
% BGD_150203_020_PED.CH1.wav,
% BGD_150204_020_BUS.CH1.wav,
% BGD_150204_020_CAF.CH1.wav,
% BGD_150204_030_BUS.CH1.wav,
% BGD_150204_030_CAF.CH1.wav,
% BGD_150204_040_BUS.CH1.wav,
% BGD_150205_030_PED.CH1.wav,
% BGD_150205_040_CAF.CH1.wav,
% BGD_150211_020_STR.CH1.wav,
% BGD_150211_030_STR.CH1.wav,
% BGD_150211_040_PED.CH1.wav,
% BGD_150212_040_STR.CH1.wav,
% BGD_150212_050_STR.CH1.wav,

% The 8~10 characters of the noise file name are change into "000" for simplification, i.e., BGD_150000_0XX_XXX.CH1.wav,


% This script used to extract the clean speech from the noisy ones.
% to match the name of the noise files from annotation

% load the annotation:
% data=loadjson('tr05_simu.json');
load('data.mat');
len = length(data);

% replaced with your director path
root_path = 'E:\myMatlab\SENN\CHIME4\';

warning off;

is_train = 0;

%% extract the clean ones
parfor i=6127:7138 % 1:4313
    % construct the noisy speech name
    speaker = data{i}.speaker;
    wsj_name = data{i}.wsj_name;
    environment = data{i}.environment;
    % 1 ~ 7138 wav files
    noisy_file_name = [speaker,'_',wsj_name,'_',environment,'.CH1.wav'];
    noisy_file_path = [root_path,'CH1', filesep, noisy_file_name];  
    noisy = audioread(noisy_file_path);
    
    % construct the noise file name
    noise_wavfile = data{i}.noise_wavfile; 
    noise_wavfile(8:10) = '000';
    noise_file_path = ['CH1_background', filesep, noise_wavfile,'.CH1.wav'];
    noise = audioread(noise_file_path);
    noise_start = round(data{i}.noise_start*16000)+1;
%     noise_end =  noise_start+length(noisy)-1;
    noise_end = round(data{i}.noise_end*16000);
    if( noise_end-noise_start+1~=length(noisy))
        fprintf('%d: %s: [%d,%d]\n', i, noisy_file_name,noise_end-noise_start+1,length(noisy));
    end
    noise = noise(noise_start:noise_end);
    noise_len = noise_end-noise_start+1;
    
    
    % clean file 
    clean = noisy - noise;
    clean_power = norm(clean);
%     audiowrite(clean_file_path,clean,16000);
    
    % for noise file seperation
    if is_train==1
        % to avoid using the first noise file
        if (strcmp(noise_wavfile(13),'1') ) % change the noise file
            noise_wavfile_train = noise_wavfile;
            noise_wavfile_train(13)=num2str(1+randi(3));
            noise_file_path = ['CH1_background', filesep, noise_wavfile_train,'.CH1.wav'];
            noise_train = audioread(noise_file_path);
            if (noise_end>length(noise_train))
                temp = randi(10);
                noise_train = noise_train(end-noise_len+1-temp:end-temp);
            else
                noise_train = noise_train(noise_start:noise_end);
            end
            noise_train = noise_train.*(norm(noise)./norm(noise_train));
            noise = noise_train;
            disp(i);
        end
    else
        % for test set
        if ~(strcmp(noise_wavfile(13),'1') ) % change the noise file
            noise_wavfile_test = noise_wavfile;
            noise_wavfile_test(13)=num2str(1);
            noise_file_path = ['CH1_background', filesep, noise_wavfile_test,'.CH1.wav'];
            noise_test = audioread(noise_file_path);
            if (noise_end>length(noise_test))
                temp = randi(10);
                noise_test = noise_test(end-noise_len+1-temp:end-temp);
            else
                noise_test = noise_test(noise_start:noise_end);
            end
            noise_test = noise_test.*(norm(noise)./norm(noise_test));
            noise = noise_test;  
            disp(i);
        end
    end
       
  
   %% 2. use org file to construct the clean and noisy one with the noise file
    org_file_name = [speaker,'_',wsj_name,'_ORG','.wav'];
    org_file_path = [root_path,'tr05_org', filesep, org_file_name];  
    org = audioread(org_file_path);
    org = org.*clean_power/norm(org);
    
    noisy = org+noise;
    noisy_file_name = [speaker,'_',wsj_name,'_',environment,'.wav'];
    if is_train==1
        wsj0_clean_file_path = [root_path,'wsj0_clean_train', filesep, org_file_name]; 
        wsj0_noisy_file_path = [root_path,'wsj0_noisy_train', filesep, noisy_file_name]; 
    else
        wsj0_clean_file_path = [root_path,'wsj0_clean_test', filesep, org_file_name]; 
        wsj0_noisy_file_path = [root_path,'wsj0_noisy_test', filesep, noisy_file_name]; 
    end
    audiowrite(wsj0_clean_file_path,org,16000);
    audiowrite(wsj0_noisy_file_path,noisy,16000);   
    fprintf('%d: SNR = %f \n',i,norm(org)/norm(noise)); 
end