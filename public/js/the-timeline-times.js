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

function toggleStar(starIcon){
    if(starIcon.hasClass('icon-star')){
        starIcon.removeClass('icon-star');
        starIcon.addClass('icon-star-empty');
    } else {
        starIcon.addClass('icon-star');
        starIcon.removeClass('icon-star-empty');
    }
}

function setArticleStatusbar(){
    $('.image-mode article').hover(
        function(){
            $(this).find('.article-status').stop(true).animate({opacity: 1}, 100);
        },
        function(){
            $(this).find('.article-status').animate({opacity: 0}, 400);
        }
    );
}

function showAlert(level, message){
    var notify = $('<div class="alert"><button type="button" class="close" data-dismiss="alert">×</button></div>');
    if (level == 'error'){
        notify.addClass('alert-error');
        notify.append('<h4>致命的なエラー</h4> ');
    } else if(level == 'warn'){
        notify.append('<h4>エラー</h4> ');
    } else if(level == 'success'){
        notify.addClass('alert-success');
        notify.append('<h4>おめでとうございます</h4> ');
    } else if(level == 'info'){
        notify.addClass('alert-info');
        notify.append('<h4>ニュース</h4> ');
    }
    notify.append('<p>' + message + '</p>');
    notify.append('<p style="text-align: right;">このウィンドウは <span class="sec">3</span> 秒後に自動的に閉じます．</p>');
    notify.css({marginTop: $(window).height()});
    notify.appendTo('#notify-block');
    notify.animate({
        marginTop: 10,
        opacity: 0.9
    }, { duration: 500, easing: 'easeOutQuad'});
    var countDown = setInterval(function(){
        var sec = Number(notify.find('.sec').text());            
        notify.find('.sec').text((sec - 1).toString());
        if ((sec - 1) <= 0){
            console.log(sec-1);
            clearInterval(countDown);
        }
    }, 1000);
    window.setTimeout(function(){
        var disappearPoint = notify.height() * -1.5;
        notify.animate({marginTop: disappearPoint, opacity: 0}, 300, function(){
            notify.alert('close');
        });
    }, 3000);
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
        load   : function(){
            changeDisplayMode($.cookie('display_mode'));
            setArticleStatusbar();
        }
    });

    changeDisplayMode($.cookie('display_mode'));

    setArticleStatusbar();
    
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
        toggleStar(pickupBtn.children('b'));
        $.ajax({
            url: pickupBtn.attr('href'),
            dataType: 'json',
            success: function(data){
                // 順調に進んだら上書きする
                if(data.pickup){
                    pickupBtn.addClass('active');
                    pickupBtn.addClass('icon-star');
                    pickupBtn.removeClass('icon-star-empty');
                } else {
                    pickupBtn.removeClass('active');
                    pickupBtn.removeClass('icon-star');
                    pickupBtn.addClass('icon-star-empty');

                }
                // showAlert('success', '正常に処理が完了しました');
            },
            error: function(data){
                // エラーが発生したらボタンを元に戻す
                pickupBtn.toggleClass('active');
                toggleStar(pickupBtn.children('b'));
                showAlert('error', 'oops! something wrong!');
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
