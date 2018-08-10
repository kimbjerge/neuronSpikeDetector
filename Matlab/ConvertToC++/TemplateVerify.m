
for i=1:400
    templatePos = rez.st(i,1);
    templateNr = rez.st(i,8);
    figure(1), 
    subplot(2,1,1);
    surf(Oldsignal(templatePos-20:templatePos+20,:)) 
    title(['Spike at ' num2str(templatePos)]);
    subplot(2,1,2);
    surf(rez.M_template(:,:,templateNr));
    title(['Template #' num2str(templateNr)]);
    pause(1);
end
