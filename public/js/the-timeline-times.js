function changeDisplayMode(display_mode){
    document.cookie = "display_mode="+display_mode;
    $('#display-container').attr("class", display_mode);
    if(display_mode == 'image-mode'){
        $('#article-container').removeAttr("class");
        $('article').attr("class", "span3");
        $('.display-mode-switcher:has(.image-mode-switch)').addClass('active');
        $('.display-mode-switcher:has(.detail-mode-switch)').removeClass('active');
    }
    else if(display_mode == 'detail-mode'){
        $('#article-container').attr("class", "span8 offset2");
        $('article').removeAttr("class");
        $('.display-mode-switcher:has(.image-mode-switch)').removeClass('active');
        $('.display-mode-switcher:has(.detail-mode-switch)').addClass('active');
    }
    $('.image-mode .article-image-container').height($('.article-image-container').width());
}

$(document).ready(function() {
	$(".various").fancybox({
		maxWidth	: 800,
		maxHeight	: 600,
		fitToView	: false,
		width		: '70%',
		height		: '70%',
		autoSize	: false,
		closeClick	: false,
		openEffect	: 'none',
		closeEffect	: 'none'
	});

    $.autopager({
        content: 'article', // コンテンツ部分のセレクタ 
        link   : '#next',     // 次ページリンクのセレクタ
        load   : function(){changeDisplayMode($.cookie('display_mode'));}
    });

    changeDisplayMode($.cookie('display_mode'));

    $('.image-mode-switch').click(function(e){
        changeDisplayMode("image-mode");
        e.preventDefault();
    });
    $('.detail-mode-switch').click(function(e){
        changeDisplayMode("detail-mode");
        e.preventDefault();
    });
    // 古の昔，小さい画面にdetail-modeを強制していた時の記憶が封印されている．．．
    // $(window).resize(function(){
    //     var w = $(window).width();
    //     var h = $(window).height();
    //     console.log("width: " + w);
    //     if(w < 780){
    //         changeDisplayMode("detail-mode");
    //     }
    //     else{
    //         changeDisplayMode(global_display_mode);
    //     }
    // });
});

$(window).resize(function(){
    console.log(".article-image-container is resized!!");
    var w = $('.article-image-container').width();
    $('.article-image-container').height(w);
});
    
