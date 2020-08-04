//setBatchMode(true);
run("Close All");

//lista = getFileList("C:\\Users\\Paulo\\Desktop\\Desktop\\imagens");
//lista.length = 1;
//for(k1=0;k1<lista.length;k1++){
for(k1=0;k1<1;k1++){
	//dir = replace(lista[k1], "/", "");
	//inputdir = "C:\\Users\\Paulo\\Desktop\\Desktop\\imagens\\"+dir+"\\original";
	//outputdir = "C:\\Users\\Paulo\\Desktop\\Desktop\\imagens\\"+dir+"\\seg_Cyto\\";
	//inputdir = "C:\\Users\\Paulo\\Desktop\\Desktop\\imagens\\10_4_5\\original";
	//outputdir = "C:\\Users\\Paulo\\Desktop\\Desktop\\imagens\\10_4_5\\seg_Cyto\\";
	inputdir = "C:\\Users\\Paulo\\Desktop\\Desktop\\hackathon\\images\\isbi2014_train\\orig";
	gt ="C:\\Users\\Paulo\\Desktop\\Desktop\\hackathon\\images\\isbi2014_train\\gt\\Nucleus";
	outputdir = "C:\\Users\\Paulo\\Desktop\\Desktop\\hackathon\\images\\isbi2014_train\\seg\\Cyto\\";
	list = getFileList(inputdir);
	for(k=0;k<list.length;k++){
		open(inputdir+"\\"+list[k]);
		segmenta(k+1, outputdir, gt);
	}
}


function nome(valor){
	if(valor<=9)
		return "00"+valor;
	if(valor<=99)
		return "0"+valor;
	return valor;
}

function segmenta(img, outputdir, gt){
	rename("OriginalImage");
	run("Bilateral Filter", "spatial=3 range=50");
	
	run("Statistical Region Merging", "q=500 showaverages");
	run("8-bit");
	run("Invert");
	
	run("8-bit");
	rename("Segmentos");
	run("Duplicate...", "title=Edges");
	run("Find Edges");
	
	for(i=0;i<=getWidth();i++)
		for(j=0;j<=getHeight();j++){
			intensidade = getPixel(i,j);
			if(intensidade>0) setPixel(i,j,255);
		}
		
	imageCalculator("Subtract create", "Segmentos","Edges");
	
	for(i=0;i<=getWidth();i++)
		for(j=0;j<=getHeight();j++){
			intensidade = getPixel(i,j);
			if(intensidade>0) setPixel(i,j,255);
		}
	
	
	
	run("Analyze Particles...", "size=30-1010 circularity=0.70-1.00 show=[Overlay Masks] display clear summarize add");
	rename("Nucleos");
	
	
	list2 = getFileList(gt);
	print(list2[0]);
	open(gt+"\\"+list2[img-1]);
	run("8-bit");
	run("Analyze Particles...", "size=30-1010 circularity=0.70-1.00 show=[Overlay Masks] display clear summarize add");
	rename("GT");	
	//wait(3000);
	nNucleos = nResults;
	nucX = newArray(nNucleos);
	nucY = newArray(nNucleos);
	cont = 0;
	for(i=0;i<nNucleos;i++){		
		roiManager("Select", i);
		nucX[i] =getResult("X",i);
		nucY[i] =getResult("Y",i);
	}
	
	//print("Nuc: "+nNucleos+" dimNuc:"+dimNuc);
	selectWindow("Nucleos");
	run("Analyze Particles...", "size=30-Infinity show=[Overlay Masks] display summarize add");	
	nSegmentos = nResults;
	segX = newArray(nSegmentos);
	segY = newArray(nSegmentos);
	for(i=0;i<nSegmentos;i++){
		segX[i] =getResult("X",i);
		segY[i] =getResult("Y",i); 
	}
	
	//encontrar o nucleo mais proximo do segmento e juntar os segmentos com respectivo nucleo
	segNuc = newArray(nSegmentos);
	for(i=0;i<nSegmentos;i++){
		menorDistancia = 100000;
		for(j=0;j<nNucleos;j++){
			
			    distX = abs(segX[i] - nucX[j]);
			    distY = abs(segY[i] - nucY[j]);
			    if(distX+distY<menorDistancia){
				    segNuc[i]=j;
				    menorDistancia = distX+distY;
			    }
		    
		}
	}
	print("Nseg: "+nSegmentos);
	rois = newArray(nSegmentos);
	for(i=0;i<nNucleos;i++){
		k=0;
		//zerar array
		for(j=0;j<nSegmentos;j++){
			    if(segNuc[j]==i){
				    roiManager("Select", j);
				    run("Create Mask");
				    rois[i] = j;
			    }
		}
		run("Convert to Mask");
		run("Dilate");
		run("Fill Holes");
		if (!File.exists(outputdir))File.makeDirectory(outputdir);
		output = outputdir+"im"+img;
		if (!File.exists(output))File.makeDirectory(output);
		saveAs("PNG", output+"\\im_"+nome(i+1)+".png");
		close();		
	}
	run("Clear Results");
	roiManager("reset");
	run("Close All");
}
