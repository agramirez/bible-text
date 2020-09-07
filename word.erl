-module(word).
-export([count/1,reader/1,reader/2,writer/2]).

reader(FileName) ->
    {ok,File}=file:open(FileName,[read]),
    ReaderId=spawn(word,reader,[File,0]),
    fun () -> 
	    ReaderId ! {next,self()},
	    receive 
		{ok,Char} ->
		    %io:format("char read: ~p~n",[Char]),
		    {ok, Char};
		eof ->
		    %io:format("eof reached~n"),
		    ReaderId ! done,
		    eof
	    end
    end.
reader(File,Count) ->
    %io:format("awaiting call to read~n"),
    receive
	{next,CallerId} ->
	    %io:format("read requested~n"),
	    CallerId ! file:read(File,1),
	    reader(File,Count+1);
	done ->
	    %io:format("done reading~n"),
	    ok
    end.

writer(Word,Index) ->
    if length(Word) == 0 ->
	    ok;
       true ->
	    CleanWord=string:lowercase(lists:reverse(Word)),
	    %io:format("writing word: ~p~n",[CleanWord]),
	    file:write_file("words/word_"++string:lowercase(CleanWord)++".count",integer_to_list(Index)++[10],[append])
    end.


count(FileName) ->
    Read=reader(FileName),
    count(Read,fun writer/2,Read(),[],0).
count(Read,Write,{ok,[Char]},Word,Index) when Char >= $A, Char =< $z ->
    %io:format("adding char to word~n"),
    count(Read,Write,Read(),[Char|Word],Index+1);
count(Read,Write,{ok,[Char]},Word,Index) ->
    %io:format("end of word reached: ~p~n",[Char]),
    Write(Word,Index),
    count(Read,Write,Read(),[],Index);
count(_Read,Write,eof,Word,Index) ->
    Write(Word,Index),
    ok.
