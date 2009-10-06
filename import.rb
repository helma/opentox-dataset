post '/*/import/?' do
	find
	halt 404, "Compound format #{params[:compound_format]} not (yet) supported" unless params[:compound_format] =~ /smiles|inchi|name/
	task = OpenTox::Task.create(@set.uri)
	Spork.spork do
		@compounds_set = Dataset.find File.join(@set.uri, "compounds")
		@features_set = Dataset.find File.join(@set.uri, "features")
		case	params[:file][:type]
		when "text/csv"
			task.start
			File.open(params[:file][:tempfile].path).each_line do |line|
				record = line.chomp.split(/,\s*/)
				compound_uri = OpenTox::Compound.new(:smiles => record[0]).uri
				feature_uri = OpenTox::Feature.new(:name => @set.name, :values => {:classification => record[1]}).uri
				@compounds_set.add compound_uri #unless @compounds_set.member? compound_uri
				@features_set.add feature_uri #unless @features_set.member? feature_uri
				# key: /dataset/:dataset/compound/:inchi
				@compound_features = Dataset.find_or_create File.join(@set.uri,'compound',OpenTox::Compound.new(:uri => compound_uri).inchi)
				@compound_features.add feature_uri
			end
			task.completed
		else
			halt 404, "File format #{request.content_type} not (yet) supported"
		end
	end
	task.uri
end
