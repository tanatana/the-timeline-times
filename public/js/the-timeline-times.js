function selectSuitableSpanwidthInImageMode(width){
    if(width < 1600){
        $('article').removeClass("span2");
        $('article').addClass("span3");
        $('.image-mode article:nth-child(6n+1)').removeAttr('style');
        $('.image-mode article:nth-child(4n+1)').css('margin-left', '0px');
    } else {
        $('article').addClass("span2");
        $('article').removeClass("span3");
        $('.image-mode article:nth-child(4n+1)').removeAttr('style');
        $('.image-mode article:nth-child(6n+1)').css('margin-left', '0px');
    }
}

function changeDisplayMode(display_mode){
    document.cookie = "display_mode="+display_mode;
    $('#display-container').attr("class", display_mode);
    if(display_mode == 'image-mode'){
        $('#article-container').removeAttr("class");
        $('.display-mode-switcher:has(.image-mode-switch)').addClass('active');
        $('.display-mode-switcher:has(.detail-mode-switch)').removeClass('active');
        var w = $(window).width();
        selectSuitableSpanwidthInImageMode(w);
    }
    else if(display_mode == 'detail-mode'){
        $('#article-container').attr("class", "span8 offset2");
        $('.display-mode-switcher:has(.image-mode-switch)').removeClass('active');
        $('.display-mode-switcher:has(.detail-mode-switch)').addClass('active');
        $('article').removeAttr("class");
    }
    $('.image-mode .article-image-container').height($('.article-image-container').width());
}

function notify(){
    
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

    $('.pickup').click(function(e){
        var pickupBtn = $(this);
        // ボタンを先にトグルしておく
        pickupBtn.toggleClass('active');

        $.ajax({
            url: pickupBtn.attr('href'),
            dataType: 'json',
            success: function(data){
                // 順調に進んだら上書きする
                if(data.pickup){
                    pickupBtn.addClass('active');
                } else {
                    pickupBtn.removeClass('active');
                }
            },
            error: function(data){
                // エラーが発生したらボタンを元に戻す
                pickupBtn.toggleClass('active');
            }
        });
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
    var article_width = $('.article-image-container').width();
    $('.article-image-container').height(article_width);
    // あんまり画面が小さかったら新しい画面でちゃんと詳細を出してあげる
    if(article_width < 780){
        $('.open-detail').addClass("various fancybox.ajax")
    } else {
        $('.open-detail').removeClass("various fancybox.ajax")
    }
    var window_width = $(window).width();
    // あんまり画面がでかくなったら横6列表示にしてあげる
    selectSuitableSpanwidthInImageMode(window_width);
});
    
