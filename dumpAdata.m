function [] = dumpAdata(afile)
    tic
    adata=mrdr('-a', '-d', afile, '-s', '1502');
    [pathstr, name] = fileparts(afile);
    save(strcat(name, '.mat'), 'adata');
    toc
end

