implement Site;

include "lyricsite.m";

modname := "plyrics";
urls := array[] of {"http://www.plyrics.com/"};

fprint, sprint: import sys;


init()
{
	sys = load Sys Sys->PATH;
	str = load String String->PATH;
	cgi = load Cgi Cgi->PATH;
	lyricutils = load Lyricutils Lyricutils->PATH;

	if(cgi == nil)
		raise "fail:loading modules";
	cgi->init();
	lyricutils->init();

	name = modname;
}

search(title, artist: list of string): (list of ref Link, string)
{
	terms := rev(artist);
	for(l := rev(title); l != nil; l = tl l)
		terms = hd l::terms;

	args := list of {("q", join(terms, " "))};
	url := "http://search.plyrics.com/cgi-bin/pseek.cgi?"+cgi->pack(args);
	say("searching in url="+url);
	(body, err) := httpget(url, "latin1");
	if(err != nil)
		return (nil, err);
	say("have html");

	rstr := "<a href=\"(http://www.plyrics.com/lyrics/[^/]*/.*.html)\"><b>(.*) LYRICS - (.*)</b></a><br>";
	hits := findall(rstr, body);
	say(sprint("have %d hits", len hits));
	links := array[len hits] of ref Link;
	j := 0;
	for(i := 0; i < len hits; i++) {
		lurl := hits[i][1];
		lartist := htmlstrip(hits[i][2]);
		ltitle := htmlstrip(hits[i][3]);
		link := Link.mk(lartist, ltitle, lurl, name, 0);
		if(hasterms(url, artist))
			links[j++] = link;
	}
	links = links[:j];
	return (rate(links, BY_URL|BY_TITLE|BY_ARTIST, title, artist), nil);
}

get(url: string): (ref Lyric, string)
{
	if(!urlallow(url, urls))
		return (nil, "bad url");

	(body, err) := httpget(url, "latin1");
	if(err != nil)
		return (nil, err);
	say("have html");

	rstr := "<img src=\"/phone_flip.gif\" alt=\"\">(([.\n]*.*)*)\n<div class=\"pmedia\">";
	hit := find(rstr, body);
	if(hit == nil) {
		say("no lyric find");
		return (nil, "no lyric found");
	}
	text := hit[1];
	text = sanitize(text);
	say("have lyric");
	return (Lyric.mk(name, url, text, 0), nil);
}

say(s: string)
{
	fprint(sys->fildes(2), "%s: %s\n", name, s);
}
